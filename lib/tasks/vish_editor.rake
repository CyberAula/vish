#
# Rake task to compile ViSH Editor JavaScript and CSS files
# Compile javascript using google's closure compiler (see http://code.google.com/closure/compiler/)
# Minify css using YUI Compressor (see http://yui.github.io/yuicompressor/)
# Also rewrite routes
#

#PATHS
VISH_EDITOR_PLUGIN_PATH = "vendor/plugins/vish_editor";
VISH_EDITOR_PATH = "../vish_editor/public/vishEditor";

# Vish Editor and Vish Viewer files and dirs :
JS_FILES_AND_DIRS = ['app/assets/js_to_compile/lang','app/assets/js_to_compile/VISH.js', 'app/assets/js_to_compile/VISH.Constant.js', 'app/assets/js_to_compile/libs','app/assets/js_to_compile/VISH.Renderer.js', 'app/assets/js_to_compile/VISH.Status.js', 'app/assets/js_to_compile/VISH.Status.Device.js', 'app/assets/js_to_compile/VISH.Utils.js', 'app/assets/js_to_compile/VISH.Editor.js', 'app/assets/js_to_compile/VISH.Editor.Utils.js', 'app/assets/js_to_compile/VISH.Editor.Text.js', 'app/assets/js_to_compile/VISH.Editor.Video.js', 'app/assets/js_to_compile/VISH.Editor.Image.js', 'app/assets/js_to_compile/VISH.Editor.Object.js', 'app/assets/js_to_compile/VISH.Editor.Presentation.js', 'app/assets/js_to_compile/VISH.Editor.Presentation.Repository.js', 'app/assets/js_to_compile/VISH.Editor.Slideset.js', 'app/assets/js_to_compile/VISH.Editor.VirtualTour.js', 'app/assets/js_to_compile/VISH.Editor.Flashcard.js', 'app/assets/js_to_compile/VISH.Editor.Slideset.Repository.js', 'app/assets/js_to_compile/VISH.Samples.js', 'app/assets/js_to_compile/VISH.Samples.API.js', 'app/assets/js_to_compile/VISH.Slides.js', 'app/assets/js_to_compile/VISH.Events.js', 'app/assets/js_to_compile/VISH.Flashcard.js', 'app/assets/js_to_compile/VISH.Quiz.js', 'app/assets/js_to_compile/VISH.Editor.Tools.js', 'app/assets/js_to_compile/VISH.Addons.js', 'app/assets/js_to_compile/VISH.VideoPlayer.js', 'app/assets/js_to_compile/VISH.Messenger.js' , 'app/assets/js_to_compile/VISH.Editor.Quiz.js', 'app/assets/js_to_compile']
CSS_FILES_AND_DIRS = ['app/assets/css_to_compile']

# Vish Viewer files and dirs
JS_VIEWER = ['libs/jquery-1.7.2.min.js', 'libs/jquery.watermark.min.js', 'libs/RegaddiChart.js', 'VISH.js', 'VISH.Constant.js', 'VISH.Configuration.js', 'VISH.QuizCharts.js', 'VISH.IframeAPI.js', 'libs/jquery-ui-1.9.2.custom.min.js', 'libs/jquery.fancybox-1.3.4.js', 'libs/jquery.qrcode.min.js', 'libs/yt_iframe_api.js', 'libs/jquery.joyride-1.0.5.js', 'libs/jquery.cookie.js', 'libs/modernizr.mq.js', 'libs/modernizr.foundation.js', 'VISH.User.js', 'VISH.Object.js', 'VISH.Renderer.js', 'VISH.Renderer.Filter.js', 'VISH.Debugging.js', 'VISH.Presentation.js', 'VISH.SlidesSelector.js', 'VISH.Text.js', 'VISH.VideoPlayer.js', 'VISH.VideoPlayer.CustomPlayer.js', 'VISH.VideoPlayer.HTML5.js', 'VISH.VideoPlayer.Youtube.js', 'VISH.ObjectPlayer.js', 'VISH.SnapshotPlayer.js', 'VISH.AppletPlayer.js', 'VISH.SlideManager.js', 'VISH.Utils.js', 'VISH.Utils.Loader.js', 'VISH.Status.js', 'VISH.Status.Device.js', 'VISH.Status.Device.Browser.js', 'VISH.Status.Device.Features.js', 'VISH.ViewerAdapter.js', 'VISH.Game.js', 'VISH.Flashcard.js',  'VISH.VirtualTour.js', 'VISH.Themes.js', 'VISH.Messenger.js', 'VISH.Messenger.Helper.js', 'VISH.Addons.js', 'VISH.Addons.IframeMessenger.js', 'VISH.Storage.js', 'VISH.Slides.js', 'VISH.Events.js', 'VISH.EventsNotifier.js', 'VISH.Quiz.js', 'VISH.Quiz.MC.js', 'VISH.Quiz.TF.js', 'VISH.Quiz.API.js', 'VISH.Events.Mobile.js', 'VISH.Recommendations.js', 'VISH.Tour.js']
CSS_VIEWER = ['customPlayer.css','fonts.css','joyride-1.0.5.css','jquery-ui-1.9.2.custom.css','jquery.fancybox-1.3.4.css','pack1templates.css','quiz.css','styles.css'];

COMPILER_JAR_PATH = "lib/tasks/compile"
JSCOMPILER_JAR_FILE = COMPILER_JAR_PATH + "/compiler.jar"
CSSCOMPILER_JAR_FILE = COMPILER_JAR_PATH + "/yuicompressor-2.4.2.jar"
JSCOMPILER_DOWNLOAD_URI = 'http://closure-compiler.googlecode.com/files/compiler-latest.zip'
CSSCOMPILER_DOWNLOAD_URI = 'http://yui.zenfs.com/releases/builder/builder_1.0.0b1.zip'


# Rake Task
namespace :vish_editor do
    
  task :prepare do
    puts "Task prepare do start"
    system "rm -rf " + VISH_EDITOR_PLUGIN_PATH + "/app/assets/*"
    system "rm -rf " + VISH_EDITOR_PLUGIN_PATH + "/app/views/*"
    system "rm -rf " + VISH_EDITOR_PATH + "/examples/contents/scorm/images"
    system "rm -rf " + VISH_EDITOR_PATH + "/examples/contents/scorm/javascripts"
    system "rm -rf " + VISH_EDITOR_PATH + "/examples/contents/scorm/stylesheets"

    system "mkdir -p " + VISH_EDITOR_PLUGIN_PATH + "/app/assets/"
    system "mkdir -p " + VISH_EDITOR_PLUGIN_PATH + "/app/views/excursions"
    system "cp -r " + VISH_EDITOR_PATH + "/images/ " + VISH_EDITOR_PLUGIN_PATH + "/app/assets/"
    system "cp -r " + VISH_EDITOR_PATH + "/stylesheets/ " + VISH_EDITOR_PLUGIN_PATH + "/app/assets/css_to_compile/"
    system "cp -r " + VISH_EDITOR_PATH + "/js/ " + VISH_EDITOR_PLUGIN_PATH + "/app/assets/js_to_compile/"

    #Copy CKEditor files to assets
    system "mkdir -p " + VISH_EDITOR_PLUGIN_PATH + "/app/assets/javascripts/ckeditor"
    system "cp -r " + VISH_EDITOR_PATH + "/js/libs/ckeditor/* " + VISH_EDITOR_PLUGIN_PATH + "/app/assets/javascripts/ckeditor/"

    #Copy Standalone JS files
    system "cp " + VISH_EDITOR_PATH + "/js/VISH.IframeAPI.js " + VISH_EDITOR_PLUGIN_PATH + "/app/assets/javascripts/"
    system "cp " + VISH_EDITOR_PATH + "/js/libs/RegaddiChart.js " + VISH_EDITOR_PLUGIN_PATH + "/app/assets/javascripts/"
    system "cp " + VISH_EDITOR_PATH + "/js/VISH.QuizCharts.js " + VISH_EDITOR_PLUGIN_PATH + "/app/assets/javascripts/"

    #Copy HTML and rewrite paths
    system "sed -n  '/<!-- Copy HTML from here -->/,/<!-- Copy HTML until here -->/p' " + VISH_EDITOR_PATH + "/viewer.html > " + VISH_EDITOR_PLUGIN_PATH + "/app/views/excursions/_vish_viewer.full.erb"
    system "sed -n  '/<!-- Copy HTML from here -->/,/<!-- Copy HTML until here -->/p' " + VISH_EDITOR_PATH + "/edit.html > " + VISH_EDITOR_PLUGIN_PATH + "/app/views/excursions/_vish_editor.full.erb"
    system "sed -i 's/vishEditor\\\/images/assets/g' " + VISH_EDITOR_PLUGIN_PATH + "/app/views/excursions/*"

    #Rewrite CSS paths
    system "sed -i 's/..\\\/..\\\/images/\\\/assets/g' " + VISH_EDITOR_PLUGIN_PATH + "/app/assets/css_to_compile/*/*css"
    system "sed -i 's/vishEditor\\\/images/assets/g' " + VISH_EDITOR_PLUGIN_PATH + "/app/assets/css_to_compile/*/*css"

    puts "Task prepare do finishs"
  end


  task :clean do
    system "rm -rf " + VISH_EDITOR_PLUGIN_PATH + "/app/assets/js_to_compile"
    system "rm -rf " + VISH_EDITOR_PLUGIN_PATH + "/app/assets/css_to_compile"
  end


  task :compile do 
    Rake::Task["vish_editor:prepare"].invoke
    
    #JavaScript files
    puts "Compiling Javascript"
    js_files = []
    JS_FILES_AND_DIRS.each do |dir|
      dir = VISH_EDITOR_PLUGIN_PATH + "/" + dir;
      if dir =~ /js$/
        js_files << dir
      else
        js_files.concat(Dir[ File.join(dir, "*.js") ].sort)
      end
    end
    js_files.uniq!
    puts "matched #{js_files.size} .js file(s)"
    compile_js(js_files)

    #CSS files
    puts "Compiling CSS"
    css_files = []
    CSS_FILES_AND_DIRS.each do |dir|
      dir = VISH_EDITOR_PLUGIN_PATH + "/" + dir;
      if dir =~ /css$/
        css_files << dir
      else
        css_files.concat(Dir[ File.join(dir, "*.css") ].sort)
        css_files.concat(Dir[ File.join(dir, "*/*.css") ].sort)
      end
    end
    css_files.uniq!
    puts "matched #{css_files.size} .css file(s)"

    #TODO
    #mergin
    #cat 1.css 2.css > mergin.css

    compile_css(css_files)

    Rake::Task["vish_editor:clean"].invoke

    #Copy files to scorm file in ViSH Editor
    system "cp -r " + VISH_EDITOR_PLUGIN_PATH + "/app/assets/* " + VISH_EDITOR_PATH + "/examples/contents/scorm/"
    #Rewrite css paths again (undo first rewriting for testing in VE)
    system "sed -i 's/\\\/assets/..\\\/..\\\/images/g' " + VISH_EDITOR_PATH + "/examples/contents/scorm/stylesheets/*/*.css"
    system "sed -i 's/assets\\\/vishEditor/images/g' " + VISH_EDITOR_PATH + "/examples/contents/scorm/stylesheets/*/*.css"
  end

  #========================================================================

  def compile_js(files)
    unless File.exist?(JSCOMPILER_JAR_FILE)
      Rake::Task["vish_editor:download_gcompiler"].invoke
    end
    unless File.exist?(JSCOMPILER_JAR_FILE)
      puts "#{JSCOMPILER_JAR_FILE} not found !"
      raise "try to run `rake vish_editor:download_gcompiler` manually to download the compiler jar"
    end

    files = [ files ] unless files.is_a?(Array)

    compiler_options = {}
    compiler_options['--js'] = files.join(' ')
    compiler_options['--compilation_level'] = 'SIMPLE_OPTIMIZATIONS'
    compiler_options['--js_output_file'] = "vishEditor.min.js"
    compiler_options['--warning_level'] = 'QUIET'
    compiler_options2 = {}
    compiler_options2['--js'] = files.join(' ')
    compiler_options2['--compilation_level'] = 'WHITESPACE_ONLY'
    compiler_options2['--formatting'] = 'PRETTY_PRINT'
    compiler_options2['--js_output_file'] = "vishEditor.js"
    compiler_options2['--warning_level'] = 'QUIET'
    
    files.each do |file|
      puts " > #{file}"
    end
    
    puts ""
    puts "----------------------------------------------------"
    puts "compiling ..."

    system "java -jar #{JSCOMPILER_JAR_FILE} #{compiler_options.to_a.join(' ')}"
    system "java -jar #{JSCOMPILER_JAR_FILE} #{compiler_options2.to_a.join(' ')}"
    puts "DONE"
    puts "----------------------------------------------------"
    puts "compiled #{files.size} javascript file(s) into vishEditor.js and vishEditor.min.js"
    puts ""

    puts "AND NOW THE VIEWER..."
    JS_VIEWER.collect! {|x| "vendor/plugins/vish_editor/app/assets/js_to_compile/" + x }
    compiler_options['--js'] = JS_VIEWER.join(' ')
    compiler_options['--js_output_file'] = "vishViewer.min.js"
    compiler_options2['--js'] = JS_VIEWER.join(' ')
    compiler_options2['--js_output_file'] = "vishViewer.js"
    
    system "java -jar #{JSCOMPILER_JAR_FILE} #{compiler_options.to_a.join(' ')}"
    system "java -jar #{JSCOMPILER_JAR_FILE} #{compiler_options2.to_a.join(' ')}"
    puts "DONE"
    puts "----------------------------------------------------"
 
    puts "compiled #{JS_VIEWER.size} javascript file(s) into vishViewer.js and vishViewer.min.js"
    puts ""
    system "mkdir -p " + VISH_EDITOR_PLUGIN_PATH + "/app/assets/javascripts"
    system "mv vishEditor.js " + VISH_EDITOR_PLUGIN_PATH + "/app/assets/javascripts/vishEditor.js"
    system "mv vishEditor.min.js " + VISH_EDITOR_PLUGIN_PATH + "/app/assets/javascripts/vishEditor.min.js"

    system "mv vishViewer.js " + VISH_EDITOR_PLUGIN_PATH + "/app/assets/javascripts/vishViewer.js"
    system "mv vishViewer.min.js " + VISH_EDITOR_PLUGIN_PATH + "/app/assets/javascripts/vishViewer.min.js"
  end


  def compile_css(files)
    unless File.exist?(CSSCOMPILER_JAR_FILE)
      # TODO: download CSS compiles
      # Rake::Task["vish_editor:download_YUIcompressor"].invoke
    end
    unless File.exist?(CSSCOMPILER_JAR_FILE)
      puts "#{CSSCOMPILER_JAR_FILE} not found !"
      raise "try to run `rake vish_editor:download_YUIcompressor` manually to download the compiler jar"
    end

    files = [ files ] unless files.is_a?(Array)

    files.each do |file|
      puts "#{file}"
    end

    puts ""
    puts "----------------------------------------------------"
    puts "compiling ..."

    files.each do |file|
      system "java -jar #{CSSCOMPILER_JAR_FILE} --type css #{file} -o #{file}"
    end
   
    puts "DONE"
    puts "----------------------------------------------------"
    puts "compiled #{files.size} css file(s)"
    puts ""

    system "mkdir -p " + VISH_EDITOR_PLUGIN_PATH + "/app/assets/stylesheets/"
    system "mv " + VISH_EDITOR_PLUGIN_PATH + "/app/assets/css_to_compile/* " + VISH_EDITOR_PLUGIN_PATH + "/app/assets/stylesheets/"
  
    #Restore vish_editor.css rails file
    system "cp " + VISH_EDITOR_PATH + "/stylesheets/vish_editor.css " + VISH_EDITOR_PLUGIN_PATH + "/app/assets/stylesheets/vish_editor.css"
  end


  desc "downloads (and extracts) the latest closure compiler.jar into COMPILER_JAR_PATH path (#{COMPILER_JAR_PATH})"
  task :download_gcompiler do
    require 'uri'; require 'net/http'; require 'tempfile'; require 'open-uri'
    puts "downloading compiler jar from: #{JSCOMPILER_DOWNLOAD_URI}"
   
    FileUtils.mkdir_p(COMPILER_JAR_PATH)
    writeOut = open(COMPILER_JAR_PATH + "/compiler-latest.zip", "wb")
    writeOut.write(open(JSCOMPILER_DOWNLOAD_URI).read)
    writeOut.close

    # -u  update files, create if necessary :
    system "unzip -u " + COMPILER_JAR_PATH + "/compiler-latest.zip -d " + COMPILER_JAR_PATH
  end

  desc "downloads (and extracts) the YUI compressor into COMPILER_JAR_PATH path (#{COMPILER_JAR_PATH})"
  task :download_YUIcompressor do
    require 'uri'; require 'net/http'; require 'tempfile'; require 'open-uri'
    puts "downloading compiler jar from: #{CSSCOMPILER_DOWNLOAD_URI}"
   
    FileUtils.mkdir_p(COMPILER_JAR_PATH)

    #TODO
    writeOut = open(COMPILER_JAR_PATH + "/YUIcompressor.zip", "wb")
    writeOut.write(open(CSSCOMPILER_DOWNLOAD_URI).read)
    writeOut.close

    # -u  update files, create if necessary :
    system "unzip -u " + COMPILER_JAR_PATH + "/YUIcompressor.zip -d " + COMPILER_JAR_PATH

    #Get YUI Comprsesor from YUI tools
    #TODO
  end

end
