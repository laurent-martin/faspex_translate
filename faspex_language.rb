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

Encoding.default_internal = Encoding::UTF_8
Encoding.default_external = Encoding::UTF_8

Asperalm::Log.instance.level=:info
Asperalm::Rest.debug=true

watson_trans_creds_file=ARGV[0]
src_folder=ARGV[1]
dest_folder=ARGV[2]
src_language=ARGV[3]
dest_language=ARGV[4]
YAML_EXT='.yml'
faspex_strings_hash=YAML.load_file(File.join(src_folder,src_language)+YAML_EXT)[src_language]

SERVICE_CREDS=JSON.parse(File.read(watson_trans_creds_file))
translator=IBMCloudWatsonTranslator.new(SERVICE_CREDS['url'],SERVICE_CREDS['apikey'],src_language,dest_language)

skips=[
  ["date", "order"],
]

# start to scan recursively here:
todo_list=[{ path: [], hash: faspex_strings_hash }]
# found sentences: key is sentence, value is list of occurences (paths in deep hash)
sentences={}
# iterate on todo list
while item=todo_list.shift do
  # iterate on all key/values of the item in todo list
  item[:hash].each do |k,v|
    # this is the new path inside
    current_path=item[:path].clone.push(k)
    # well, lets skips some funny elements
    next if skips.include?(current_path)
    # what type of value is this?
    case v
    when String
      # lets skip strings that contain only formatting, this will need manual adjustment
      if v.gsub(/%[A-Za-z]/,'').gsub(/%\{[^}]+\}/,'').gsub(/[^[A-Za-z]]/,'').empty?
        Asperalm::Log.log.debug("skip: #{v}")
        next
      end
      # add or create occurence to list for this sentence.
      (sentences[v]||=[]).push(current_path)
    when Hash
      # need to go deeper
      todo_list.push({ hash: v, path: current_path})
    when Array
      raise "unexpected array: #{v} at #{current_path}" unless v.map{|i| i.nil? ? String : i.class}.uniq.eql?([String])
      # TODO: translate array
    else Asperalm::Log.log.debug("skip: #{v.class} at #{current_path}");
    end
  end
end

original_messages=sentences.keys
# replace %{xxx} with MY_xxx_YM because special characters confuse translator
orig_msg_with_tags=original_messages.map{|i| i.gsub(/%\{([^}]+)\}/,'MY_\1_YM')}
translated = translator.translate_sentences(orig_msg_with_tags)
# replace back MY_xxx_YM with %{xxx} in translated version
translated.map!{|i| i.gsub(/MY_(.+?)_YM/,'%{\1}')}
# change to translated version in structure
original_messages.each do |msg|
  # get corresponding translation (it is in same order)
  translation=translated.shift
  # change each occurence
  sentences[msg].each do |path|
    # start from root, re-use same structure, so that skipped items will remain
    here=faspex_strings_hash
    # navigate folowing path
    while k=path.shift
      here=here[k]
    end
    # finally change it
    here.replace(translation)
  end
end
# create new expected structure
new_directionary={dest_language=>faspex_strings_hash}
# write result
dest_file=File.join(dest_folder,dest_language+YAML_EXT)
File.write(dest_file,new_directionary.to_yaml)
