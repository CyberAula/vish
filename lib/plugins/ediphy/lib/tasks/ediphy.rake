# encoding: utf-8
#
# Rake task to import ediphy into vish

#PATHS
DALI_EDITOR_PLUGIN_PATH = "lib/plugins/ediphy"
DALI_EDITOR_PATH = "../ediphy"

PRIVATE_ASSETS_ADAMS = ""

######################
# 			REGEXP       #
######################
#API
REGEX_SAVE = "http://127.0.0.1:8081/saveConfig"
REGEX_GET =  "http://127.0.0.1:8081/getConfig"
REGEX_API_PLUGIN = 'plugins/"'

#INDEX
REGEX_LIB = 'src\="lib'
REGEX_JS = 'src\="js'
REGEX_BUNDLE = 'src\="app-bundle.js"'
REGEX_VISOR_BUNDLE = 'src\="<%=relativePath%>../../visor-bundle.js"'
REGEX_CSS = 'href\="/css/textStyles.css"'

REGEX_PREVISOR = '>css/'

REGEX_ANIM_VERT_CSS2 = 'href\="/css/jquery-animVert.css"'
REGEX_CAJASCOLOR2 = 'href\="/css/cajascolor.css"'
REGEX_RELATIVE_PATH = 'relativePath'

#IMAGES
REGEX_IMAGES_SRC = 'src\="images'
REGEX_IMAGES_SRC2 = '\.\./images'
REGEX_IMAGES_PLAIN = 'images/'

REGEX_IMAGES_SRC_PREV = 'src\="/images'

COMMENT_TO_AVOID_COMPRESSION = "\/\* DO NOT REMOVE THIS COMMENT, It turns off compression during the asset precompilation phase, to avoid failures caused by unwanted side effects of compression., no_asset_compression \*/"

######################
# 	PATHS REWRITES   #
######################

#API
SAVE_URL_DALI = "url"
GET_URL_DALI = "url"
PATH_API_PLUGIN = '\/assets/plugins/"'

#INDEX
PATH_LIB = 'src\=\"/assets/lib'
PATH_JS = 'src\=\"/assets/js'
PATH_PLUGINS = 'src\=\"/assets/editor/plugins.js"'
PATH_BUNDLE = 'src\=\"/assets/editor/app-bundle.js"'
PATH_VISOR_BUNDLE = 'src\=\"/assets/editor/visor-bundle.js"'
PATH_CSS_TEXTSTYLES_VISOR = 'href\=\"/assets/ediphy_documents/textStyles.css"'

PATH_PREVISOR = '>ediphy_documents/'

PATH_STYLE_HTML = 'href\="css/style.css"'
PATH_CAJASCOLOR_HTML = 'href\="css/cajascolor.css"'
PATH_ANIM_VERT_HTML = 'href\="css/jquery-animVert.css"'
PATH_EJERCICIOS_HTML = 'href\="css/ejercicios.css"'
PATH_COMPILEDSASS_HTML = 'href\="css/compiledsass.css"'
PATH_CSS_TEXTSTYLES_HTML = 'href\=\"css/textStyles.css"'

PATH_STYLE_SCORM = 'href\="../css/style.css"'
PATH_CAJASCOLOR_SCORM = 'href\="../css/cajascolor.css"'
PATH_ANIM_VERT_SCORM = 'href\="../css/jquery-animVert.css"'
PATH_EJERCICIOS_SCORM = 'href\="../css/ejercicios.css"'
PATH_COMPILEDSASS_SCORM = 'href\="../css/compiledsass.css"'
PATH_CSS_TEXTSTYLES_SCORM = 'href\=\"../css/textStyles.css"'

PATH_DIST = "/assets/lib/visor/dist.zip"
PATH_INDEXEJS = "/lib/visor/index.ejs"

PATH_SCORM = "/assets/lib/scorm/scorm.zip"
PATH_SCORM_NAV = '/assets/lib/scorm/scorm_nav.js'

#IMAGES
PATH_IMAGES_SRC = 'src\="/assets/images'
PATH_IMAGES_SRC2 = '/assets/images'
PATH_IMAGES_PLAIN = '/assets/images/'

PATH_IMAGES_HTML = 'src\="images"'
REPLACE_VISH_PATH = 'vishPath'

namespace :ediphy do

	task :rebuild do
		Rake::Task["ediphy:import"].invoke
    	Rake::Task["ediphy:rewrite_api_paths"].invoke
    	Rake::Task["ediphy:rewrite_entry_point_paths"].invoke
    	Rake::Task["ediphy:rewrite_images_paths"].invoke
    	Rake::Task["ediphy:rewrite_visor_path"].invoke
    	Rake::Task["ediphy:private_assets"].invoke
	end

	task :full_rebuild do
		system "mkdir " + DALI_EDITOR_PLUGIN_PATH + "/app/"
		system "mkdir " + DALI_EDITOR_PLUGIN_PATH + "/app/views"
		system "mkdir " + DALI_EDITOR_PLUGIN_PATH + "/app/views/ediphy_documents"
		Rake::Task["ediphy:rebuild"].invoke

		system "cp " + DALI_EDITOR_PATH + "/dist/index.html " +  DALI_EDITOR_PLUGIN_PATH + "/app/views/ediphy_documents/_ediphy_document.full.erb"
	end


	task :import do
		puts "Importing Ediphy into VISH"

		system "rm -rf " + DALI_EDITOR_PLUGIN_PATH + "/app/assets"
		system "rm -rf " + DALI_EDITOR_PLUGIN_PATH + "/extras"

		
		system "mkdir " + DALI_EDITOR_PLUGIN_PATH + "/app/assets"
		system "mkdir " + DALI_EDITOR_PLUGIN_PATH + "/app/assets/images"
		system "mkdir " + DALI_EDITOR_PLUGIN_PATH + "/app/assets/stylesheets"
		system "mkdir " + DALI_EDITOR_PLUGIN_PATH + "/app/assets/stylesheets/ediphy_documents"
		system "mkdir " + DALI_EDITOR_PLUGIN_PATH + "/app/assets/javascripts"
		system "mkdir " + DALI_EDITOR_PLUGIN_PATH + "/app/assets/javascripts/editor"
		
		system "mkdir " + DALI_EDITOR_PLUGIN_PATH + "/extras"
		#system "mkdir " + DALI_EDITOR_PLUGIN_PATH + "/vendor/lib"
		#system "mkdir " + DALI_EDITOR_PLUGIN_PATH + "/vendor/lib/visor"
		#system "mkdir " + DALI_EDITOR_PLUGIN_PATH + "/vendor/lib/scorm"

		system "cp -r " + DALI_EDITOR_PATH + "/dist/images " +  DALI_EDITOR_PLUGIN_PATH + "/app/assets/images"
		system "cp -r " + DALI_EDITOR_PATH + "/dist/lib " +  DALI_EDITOR_PLUGIN_PATH + "/app/assets/javascripts"
		
		#system "cp -r " + DALI_EDITOR_PATH + "/plugins " +  DALI_EDITOR_PLUGIN_PATH + "/app/assets/javascripts/plugins"
		system "cp " + DALI_EDITOR_PATH + "/dist/prod/app-bundle.min.js " +  DALI_EDITOR_PLUGIN_PATH + "/app/assets/javascripts/editor/app-bundle.js"
		system "cp " + DALI_EDITOR_PATH + "/dist/prod/visor-bundle.min.js " +  DALI_EDITOR_PLUGIN_PATH + "/app/assets/javascripts/editor/visor-bundle.js"
		
		system "sed -i '1i" + COMMENT_TO_AVOID_COMPRESSION + "' "+ DALI_EDITOR_PLUGIN_PATH + "/app/assets/javascripts/editor/app-bundle.js"
		system "sed -i '1i" + COMMENT_TO_AVOID_COMPRESSION + "' "+ DALI_EDITOR_PLUGIN_PATH + "/app/assets/javascripts/editor/visor-bundle.js"
		#system "cp " + DALI_EDITOR_PATH + "/dist/lib/visor/index.ejs " +  DALI_EDITOR_PLUGIN_PATH + "/vendor/lib/visor/index.ejs"
		#system "cp " + DALI_EDITOR_PATH + "/dist/lib/visor/index_exercise.ejs " +  DALI_EDITOR_PLUGIN_PATH + "/vendor/lib/visor/index_exercise.ejs"
		#system "cp " + DALI_EDITOR_PATH + "/dist/lib/scorm/scorm_nav.ejs " +  DALI_EDITOR_PLUGIN_PATH + "/vendor/lib/scorm/scorm_nav.ejs"
	end

	task :rewrite_api_paths do
		system "mv " + DALI_EDITOR_PLUGIN_PATH + "/app/assets/javascripts/lib/jspdf.debug.js " +  DALI_EDITOR_PLUGIN_PATH + "/app/assets/javascripts/lib/jspdf.js"
		#system "sed -i 's#" + REGEX_SAVE+ "#" + SAVE_URL_DALI + "#g' " + DALI_EDITOR_PLUGIN_PATH + "/app/assets/javascripts/editor/app-bundle.js"
		#system "sed -i 's#" + REGEX_GET+ "#" + GET_URL_DALI + "#g' " + DALI_EDITOR_PLUGIN_PATH + "/app/assets/javascripts/editor/app-bundle.js"
	end

	task :rewrite_entry_point_paths do
		#REWRITE INDEX.HTML.ERB
		system "sed -i 's#" + REGEX_LIB+ "#" + PATH_LIB + "#g' " + DALI_EDITOR_PLUGIN_PATH + "/app/views/ediphy_documents/_ediphy_document.full.erb"
		system "sed -i 's#" + REGEX_JS+ "#" + PATH_JS + "#g' " + DALI_EDITOR_PLUGIN_PATH + "/app/views/ediphy_documents/_ediphy_document.full.erb"
		system "sed -i 's#" + REGEX_BUNDLE+ "#" + PATH_BUNDLE + "#g' " + DALI_EDITOR_PLUGIN_PATH + "/app/views/ediphy_documents/_ediphy_document.full.erb"
	end

	task :rewrite_images_paths do
		system "sed -i 's#" + REGEX_IMAGES_SRC+ "#" + PATH_IMAGES_SRC + "#g' " + DALI_EDITOR_PLUGIN_PATH + "/vendor/lib/visor/index.ejs"
		#system "sed -i 's#" + REGEX_IMAGES_SRC2+ "#" + PATH_IMAGES_SRC2 + "#g' " + DALI_EDITOR_PLUGIN_PATH + "/app/assets/stylesheets/ediphy_documents/textStyles.css"
		#system "sed -i 's#" + REGEX_IMAGES_PLAIN+ "#" + PATH_IMAGES_PLAIN + "#g' " + DALI_EDITOR_PLUGIN_PATH + "/app/assets/javascripts/editor/app-bundle.js"
	end

	task :rewrite_visor_path do

		system "sed -i 's#" + REGEX_LIB+ "#" + PATH_LIB + "#g' " + DALI_EDITOR_PLUGIN_PATH + "/app/assets/javascripts/lib/visor/index.ejs"
		system "sed -i 's#" + REGEX_JS+ "#" + PATH_JS + "#g' " + DALI_EDITOR_PLUGIN_PATH + "/app/assets/javascripts/lib/visor/index.ejs"
		system "sed -i 's#" + REGEX_BUNDLE+ "#" + PATH_BUNDLE + "#g' " + DALI_EDITOR_PLUGIN_PATH + "/app/assets/javascripts/lib/visor/index.ejs"
	end

	task :private_assets do
		#system "rm -rf " + DALI_EDITOR_PLUGIN_PATH + "/vendor"
		#extract_zip(PRIVATE_ASSETS_ADAMS, DALI_EDITOR_PLUGIN_PATH + "/vendor")
	end

	def extract_zip(file, destination)
	  FileUtils.mkdir_p(destination)

	  Zip::File.open(file) do |zip_file|
	    zip_file.each do |f|
	      fpath = File.join(destination, f.name)
	      zip_file.extract(f, fpath) unless File.exist?(fpath)
	    end
	  end
	end

end