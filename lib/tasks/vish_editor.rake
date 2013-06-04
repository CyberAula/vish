#
# A javascript compile rake task (uses google's closure compiler).
# @see http://code.google.com/closure/compiler/
#

#PATHS
VISH_EDITOR_PLUGIN_PATH = "vendor/plugins/vish_editor";
VISH_EDITOR_PATH = "../vish_editor/public/vishEditor";

# Vish Editor and Vish Viewer files and dirs :
JS_FILES_AND_DIRS = ['app/assets/js_to_compile/lang','app/assets/js_to_compile/VISH.js', 'app/assets/js_to_compile/VISH.Constant.js', 'app/assets/js_to_compile/libs','app/assets/js_to_compile/VISH.Renderer.js', 'app/assets/js_to_compile/VISH.Status.js', 'app/assets/js_to_compile/VISH.Status.Device.js', 'app/assets/js_to_compile/VISH.Utils.js', 'app/assets/js_to_compile/VISH.Editor.js', 'app/assets/js_to_compile/VISH.Editor.Utils.js', 'app/assets/js_to_compile/VISH.Editor.Text.js', 'app/assets/js_to_compile/VISH.Editor.Video.js', 'app/assets/js_to_compile/VISH.Editor.Image.js', 'app/assets/js_to_compile/VISH.Editor.Object.js', 'app/assets/js_to_compile/VISH.Editor.Presentation.js', 'app/assets/js_to_compile/VISH.Editor.Presentation.Repository.js', 'app/assets/js_to_compile/VISH.Editor.Slideset.js', 'app/assets/js_to_compile/VISH.Editor.VirtualTour.js', 'app/assets/js_to_compile/VISH.Editor.Flashcard.js', 'app/assets/js_to_compile/VISH.Editor.Slideset.Repository.js', 'app/assets/js_to_compile/VISH.Samples.js', 'app/assets/js_to_compile/VISH.Samples.API.js', 'app/assets/js_to_compile/VISH.Slides.js', 'app/assets/js_to_compile/VISH.Events.js', 'app/assets/js_to_compile/VISH.Flashcard.js', 'app/assets/js_to_compile/VISH.Quiz.js', 'app/assets/js_to_compile/VISH.Editor.Tools.js', 'app/assets/js_to_compile/VISH.Addons.js', 'app/assets/js_to_compile/VISH.VideoPlayer.js', 'app/assets/js_to_compile/VISH.Messenger.js' , 'app/assets/js_to_compile/VISH.Editor.Quiz.js', 'app/assets/js_to_compile']

# Vish Viewer files and dirs
ONLY_VIEWER = ['libs/jquery-1.7.2.min.js', 'libs/jquery.watermark.min.js', 'libs/RegaddiChart.js', 'VISH.js', 'VISH.Constant.js', 'VISH.Configuration.js', 'VISH.QuizCharts.js', 'VISH.IframeAPI.js', 'libs/jquery-ui-1.9.2.custom.min.js', 'libs/jquery.fancybox-1.3.4.js', 'libs/jquery.qrcode.min.js', 'libs/yt_iframe_api.js', 'libs/jquery.joyride-1.0.5.js', 'libs/jquery.cookie.js', 'libs/modernizr.mq.js', 'libs/modernizr.foundation.js', 'VISH.User.js', 'VISH.Object.js', 'VISH.Renderer.js', 'VISH.Renderer.Filter.js', 'VISH.Debugging.js', 'VISH.Presentation.js', 'VISH.SlidesSelector.js', 'VISH.Text.js', 'VISH.VideoPlayer.js', 'VISH.VideoPlayer.CustomPlayer.js', 'VISH.VideoPlayer.HTML5.js', 'VISH.VideoPlayer.Youtube.js', 'VISH.ObjectPlayer.js', 'VISH.SnapshotPlayer.js', 'VISH.AppletPlayer.js', 'VISH.SlideManager.js', 'VISH.Utils.js', 'VISH.Utils.Loader.js', 'VISH.Status.js', 'VISH.Status.Device.js', 'VISH.Status.Device.Browser.js', 'VISH.Status.Device.Features.js', 'VISH.ViewerAdapter.js', 'VISH.Game.js', 'VISH.Flashcard.js',  'VISH.VirtualTour.js', 'VISH.Themes.js', 'VISH.Messenger.js', 'VISH.Messenger.Helper.js', 'VISH.Addons.js', 'VISH.Addons.IframeMessenger.js', 'VISH.Storage.js', 'VISH.Slides.js', 'VISH.Events.js', 'VISH.EventsNotifier.js', 'VISH.Quiz.js', 'VISH.Quiz.MC.js', 'VISH.Quiz.TF.js', 'VISH.Quiz.API.js', 'VISH.Events.Mobile.js', 'VISH.Recommendations.js', 'VISH.Tour.js']

COMPILER_JAR_PATH = "lib/tasks/compile"
COMPILER_JAR_FILE = COMPILER_JAR_PATH + "/compiler.jar"
COMPILER_DOWNLOAD_URI = 'http://closure-compiler.googlecode.com/files/compiler-latest.zip'


# Rake Task
namespace :vish_editor do
    
  task :prepare do
    puts "Task prepare do start"
    system "rm -rf " + VISH_EDITOR_PLUGIN_PATH + "/app/assets/*"
    system "rm -rf " + VISH_EDITOR_PLUGIN_PATH + "/app/views/*"
    system "mkdir -p " + VISH_EDITOR_PLUGIN_PATH + "/app/assets/"
    system "mkdir -p " + VISH_EDITOR_PLUGIN_PATH + "/app/views/excursions"
    system "cp -r " + VISH_EDITOR_PATH + "/images/ " + VISH_EDITOR_PLUGIN_PATH + "/app/assets/"
    system "cp -r " + VISH_EDITOR_PATH + "/stylesheets/ " + VISH_EDITOR_PLUGIN_PATH + "/app/assets/"
    system "cp -r " + VISH_EDITOR_PATH + "/js/ " + VISH_EDITOR_PLUGIN_PATH + "/app/assets/js_to_compile/"

    #Copy CKEditor files to assets
    system "mkdir -p " + VISH_EDITOR_PLUGIN_PATH + "/app/assets/javascripts/ckeditor"
    system "cp -r " + VISH_EDITOR_PATH + "/js/libs/ckeditor/* " + VISH_EDITOR_PLUGIN_PATH + "/app/assets/javascripts/ckeditor/"

    #Copy Standalone JS files
    system "cp " + VISH_EDITOR_PATH + "/js/VISH.IframeAPI.js " + VISH_EDITOR_PLUGIN_PATH + "/app/assets/javascripts/"
    system "cp " + VISH_EDITOR_PATH + "/js/libs/RegaddiChart.js " + VISH_EDITOR_PLUGIN_PATH + "/app/assets/javascripts/"
    system "cp " + VISH_EDITOR_PATH + "/js/VISH.QuizCharts.js " + VISH_EDITOR_PLUGIN_PATH + "/app/assets/javascripts/"

    #Copy HTML
    system "sed -n  '/<!-- Copy HTML from here -->/,/<!-- Copy HTML until here -->/p' " + VISH_EDITOR_PATH + "/viewer.html > " + VISH_EDITOR_PLUGIN_PATH + "/app/views/excursions/_vish_viewer.full.erb"
    system "sed -n  '/<!-- Copy HTML from here -->/,/<!-- Copy HTML until here -->/p' " + VISH_EDITOR_PATH + "/edit.html > " + VISH_EDITOR_PLUGIN_PATH + "/app/views/excursions/_vish_editor.full.erb"
    system "sed -i 's/vishEditor\\\/images/assets/g' " + VISH_EDITOR_PLUGIN_PATH + "/app/views/excursions/*"

    system "sed -i 's/..\\\/..\\\/images/\\\/assets/g' " + VISH_EDITOR_PLUGIN_PATH + "/app/assets/stylesheets/*/*css"
    system "sed -i 's/vishEditor\\\/images/assets/g' " + VISH_EDITOR_PLUGIN_PATH + "/app/assets/stylesheets/*/*css"

    puts "Task prepare do finishs"
  end

  task :clean do
    system "rm -rf " + VISH_EDITOR_PLUGIN_PATH + "/app/assets/js_to_compile"
  end

  task :compile do 
    Rake::Task["vish_editor:prepare"].invoke
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
    Rake::Task["vish_editor:clean"].invoke
  end

  desc "downloads (and extracts) the latest closure compiler.jar into COMPILER_JAR_PATH path (#{COMPILER_JAR_PATH})"
  task :download_jar do
    require 'uri'; require 'net/http'; require 'tempfile'; require 'open-uri'
    puts "downloading compiler jar from: #{COMPILER_DOWNLOAD_URI}"
   
    FileUtils.mkdir_p(COMPILER_JAR_PATH)
    writeOut = open(COMPILER_JAR_PATH + "/compiler-latest.zip", "wb")
    writeOut.write(open(COMPILER_DOWNLOAD_URI).read)
    writeOut.close

    # -u  update files, create if necessary :
    system "unzip -u " + COMPILER_JAR_PATH + "/compiler-latest.zip -d " + COMPILER_JAR_PATH
  end

  #========================================================================

  def compile_js(files)
    unless File.exist?(COMPILER_JAR_FILE)
      Rake::Task["vish_editor:download_jar"].invoke
    end
    unless File.exist?(COMPILER_JAR_FILE)
      puts "#{COMPILER_JAR_FILE} not found !"
      raise "try to run `rake vish_editor:download_jar` manually to download the compiler jar"
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

    system "java -jar #{COMPILER_JAR_FILE} #{compiler_options.to_a.join(' ')}"
    system "java -jar #{COMPILER_JAR_FILE} #{compiler_options2.to_a.join(' ')}"
    puts "DONE"
    puts "----------------------------------------------------"
    puts "compiled #{files.size} javascript file(s) into vishEditor.js and vishEditor.min.js"
    puts ""

    puts "AND NOW THE VIEWER..."
    ONLY_VIEWER.collect! {|x| "vendor/plugins/vish_editor/app/assets/js_to_compile/" + x }
    compiler_options['--js'] = ONLY_VIEWER.join(' ')
    compiler_options['--js_output_file'] = "vishViewer.min.js"
    compiler_options2['--js'] = ONLY_VIEWER.join(' ')
    compiler_options2['--js_output_file'] = "vishViewer.js"
    
    system "java -jar #{COMPILER_JAR_FILE} #{compiler_options.to_a.join(' ')}"
    system "java -jar #{COMPILER_JAR_FILE} #{compiler_options2.to_a.join(' ')}"
    puts "DONE"
    puts "----------------------------------------------------"
 
    puts "compiled #{ONLY_VIEWER.size} javascript file(s) into vishViewer.js and vishViewer.min.js"
    puts ""
    system "mkdir -p " + VISH_EDITOR_PLUGIN_PATH + "/app/assets/javascripts"
    system "mv vishEditor.js " + VISH_EDITOR_PLUGIN_PATH + "/app/assets/javascripts/vishEditor.js"
    system "mv vishEditor.min.js " + VISH_EDITOR_PLUGIN_PATH + "/app/assets/javascripts/vishEditor.min.js"

    system "mv vishViewer.js " + VISH_EDITOR_PLUGIN_PATH + "/app/assets/javascripts/vishViewer.js"
    system "mv vishViewer.min.js " + VISH_EDITOR_PLUGIN_PATH + "/app/assets/javascripts/vishViewer.min.js"
  end

end
