#!/usr/bin/env ruby
# Laurent Martin 2014, updated jan 2020 Faspex 4.4.0
require 'yaml' # same as psych, see module Psych
require 'json'
require 'asperalm/rest'
require 'asperalm/log'

class IBMCloudWatsonTranslator
  def initialize(url,apikey,source,destination)
    @model="#{source}-#{destination}"
    @wt_api=Asperalm::Rest.new({
      base_url: url,
      auth: {:type=>:basic,:username=>'apikey',:password=>apikey},
      session_cb: lambda {|http| http.read_timeout=300}
    })
  end

  def translate_sentences(origs)
    result=@wt_api.create('v3/translate?version=2018-05-01',{'model_id'=>@model,'text'=>origs})[:data]
    return result['translations'].map{|i|i['translation']}
  end
end

# @param faspex_strings_hash Faspex sentence dictionary (basically the yaml file hash)
# @return occurrences of sentences in hash {'Hello' => [["path1key1","path1key2"],...]}
# We assume that the same sting will anyway be translated the same way by translator
# this saves having to translate the same string twice
def faspex_message_occurences(faspex_strings_hash)
  # start to scan recursively here:
  # elements: "path" current path in hash, "hash" current node to analyze in hash
  todo_list=[{ path: [], hash: faspex_strings_hash }]
  # result
  sentences_paths={}
  # iterate on todo list
  while item=todo_list.shift do
    # iterate on all key/values of items in TODO list
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

# @param a_orig_dict original Faspex dictionary (hash from yaml)
# @param a_sentences_paths result from previous step
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

if ARGV.length != 3
  print "Usage:\n"
  print "  #{$0} <watson credential file> <in folder> <out folder> <in language> <out language>\n"
  print "Example:\n"
  print "  #{$0} my_watson_creds /opt/aspera/faspex/config/locales/en.yml /opt/aspera/faspex/config/locales/ja.yml\n"
  Process.exit(1)
end

# global stuff
Encoding.default_internal = Encoding::UTF_8
Encoding.default_external = Encoding::UTF_8
Asperalm::Log.instance.level=:warn
Asperalm::Rest.debug=false

# get command line args
watson_trans_creds_file=ARGV[0]
original_file=ARGV[1]
translated_file=ARGV[2]

src_language=File.basename(original_file,'.yml')
dest_language=File.basename(translated_file,'.yml')

[src_language,dest_language].each do |l|
  if !l.match(/^[a-z][a-z]$/)
    print "Error: language #{l} does not match two letters\n"
    Process.exit(1)
  end
end

print "Translate #{src_language} to #{dest_language}\n"

# read Faspex dictionary
FASPEX_DICTIONARY=YAML.load_file(original_file)
# watson credentials saved from web UI or API
WATSON_TRANSLATION_SERVICE_CREDS=JSON.parse(File.read(watson_trans_creds_file))

translator=IBMCloudWatsonTranslator.new(WATSON_TRANSLATION_SERVICE_CREDS['url'],WATSON_TRANSLATION_SERVICE_CREDS['apikey'],src_language,dest_language)
# extract sentences and occurrences in dictionary
sentences_paths=faspex_message_occurences(FASPEX_DICTIONARY)
# translate and generate new dictionary
new_dictionary=translate_dictionary(FASPEX_DICTIONARY,sentences_paths,translator,src_language,dest_language)
# write result
File.write(translated_file,YAML.dump(new_dictionary,line_width: 160, canonical: false))
