#!/usr/bin/env ruby
# Laurent Martin 2014, updated jan 2020 Faspex 4.4.0
require 'yaml'
require 'json'
require 'asperalm/rest'
require 'asperalm/log'

class IBMCloudWatsonTranslator
  def initialize(url,apikey,source,destination)
    @model="#{source}-#{destination}"
    @wt_api=Asperalm::Rest.new({:base_url => url,:auth=>{:type=>:basic,:username=>'apikey',:password=>apikey}})
  end

  def translate_sentences(origs)
    result=@wt_api.create('v3/translate?version=2018-05-01',{'model_id'=>@model,'text'=>origs})[:data]
    return result['translations'].map{|i|i['translation']}
  end
end

def faspex_message_occurences(faspex_strings_hash)
  # start to scan recursively here:
  todo_list=[{ path: [], hash: faspex_strings_hash }]
  # found sentences_paths: key is sentence, value is list of occurrences (paths in deep hash)
  # {'Hello' => [["key1","key2"],...]}
  sentences_paths={}
  # iterate on todo list
  while item=todo_list.shift do
    # iterate on all key/values of the item in todo list
    item[:hash].each do |k,v|
      # this is the new path inside
      current_path=item[:path].clone.push(k)
      # well, lets skips some funny elements
      #next if skips.include?(current_path)
      # what type of value is this?
      case v
      when String
        # lets skip strings that contain only formatting, this will need manual adjustment
        if v.gsub(/%[A-Za-z]/,'').gsub(/%\{[^}]+\}/,'').gsub(/[^[A-Za-z]]/,'').empty?
          Asperalm::Log.log.debug("skip: #{v}")
          next
        end
        # add or create occurrence to list for this sentence.
        (sentences_paths[v]||=[]).push(current_path)
      when Hash
        # need to go deeper
        todo_list.push({ hash: v, path: current_path})
      when Array
        inside_types=v.map{|i|i.class}.uniq
        if inside_types.eql?([Symbol])
          Asperalm::Log.log.debug("skip array: #{v}")
          next
        end
        raise "unexpected array: #{v} at #{current_path}" unless [[String],[NilClass,String]].include?(inside_types)
        # TODO: translate array
        Asperalm::Log.log.debug("todo: #{v}")
      else Asperalm::Log.log.debug("skip: #{v.class} at #{current_path}");
      end
    end
  end
  return sentences_paths
end

def translate_dictionary(a_orig_dict,a_sentences_paths,a_translator,a_src_lang,a_dst_lang)
  # we could also make a deep copy
  new_dict=a_orig_dict
  # replace %{xxx} with MY_xxx_YM because special characters %,{,} confuse translator
  orig_msg_with_tags=a_sentences_paths.keys.map{|i| i.gsub(/%\{([^}]+)\}/,'MY_\1_YM')}
  translated = a_translator.translate_sentences(orig_msg_with_tags)
  # replace back MY_xxx_YM with %{xxx} in translated version
  translated.map!{|i| i.gsub(/MY_(.+?)_YM/,'%{\1}')}
  # change to translated version in structure
  a_sentences_paths.each do |msg,paths|
    # get corresponding translation (it is in same order)
    translation=translated.shift
    # change each occurrence
    paths.each do |path|
      # replace string in new_dict at specified path
      path.inject(new_dict){|m,i|m[i]}.replace(translation)
    end
  end
  # create new expected structure: first key is language
  return {a_dst_lang=>new_dict[a_src_lang]}
end

def lang_file(folder,lang)
  return File.join(folder,lang)+'.yml'
end

# global stuff
Encoding.default_internal = Encoding::UTF_8
Encoding.default_external = Encoding::UTF_8
Asperalm::Log.instance.level=:warn
Asperalm::Rest.debug=false

# get command line args
watson_trans_creds_file=ARGV[0]
src_folder=ARGV[1]
dest_folder=ARGV[2]
src_language=ARGV[3]
dest_language=ARGV[4]

# read faspex dictionary
FASPEX_DICTIONARY=YAML.load_file(lang_file(src_folder,src_language))
WATSON_TRANSLATION_SERVICE_CREDS=JSON.parse(File.read(watson_trans_creds_file))

translator=IBMCloudWatsonTranslator.new(WATSON_TRANSLATION_SERVICE_CREDS['url'],WATSON_TRANSLATION_SERVICE_CREDS['apikey'],src_language,dest_language)
# extract sentences and occurrences in dictionary
sentences_paths=faspex_message_occurences(FASPEX_DICTIONARY)
# translate and generate new dictionary
new_dictionary=translate_dictionary(FASPEX_DICTIONARY,sentences_paths,translator,src_language,dest_language)
# write result
File.write(lang_file(dest_folder,dest_language),new_dictionary.to_yaml)
