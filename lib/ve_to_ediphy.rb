class VETOEDIPHY

  def self.translate(vish_excursion_json)
    excursion_json = JSON.parse(vish_excursion_json)
    names = self.generate_names(excursion_json)
    nav_items_by_id = self.create_nav_items_by_id(names["navs_names"], names["navs_boxes"])
    contained_views_by_id = self.create_contained_views_by_id(names["names_cv"], names["cv_boxes"], names["cv_marks"])
    nav_items_ids = self.create_nav_items_ids(names["navs_names"])
    nav_item_selected = names["navs_names"].values[0] # TODO Comprobar que hay al menos una slide
    view_toolbars_by_id = self.create_view_toolbars(names["navs_names"], names["names_cv"], excursion_json["theme"])
    boxes_and_plugin_toolbars = self.create_boxes_and_plugin_toolbars( names["navs_boxes"], names["cv_boxes"], names["templates"], names["plugins"])
    global_config = self.create_global_config(excursion_json)
    marks_by_id = names["marks"]
    exercises = self.create_exercises(names["navs_boxes"],  names["cv_boxes"], boxes_and_plugin_toolbars["toolbars"], boxes_and_plugin_toolbars["answers"], boxes_and_plugin_toolbars["current_answers"])
    {
        "present" => {
            "version"=> 2.1,
            "lastActionDispatched" => "@@INIT",
            "globalConfig" => global_config,
            "displayMode"=> "list",
            "indexSelected"=> -1,
            "navItemsById"=> nav_items_by_id,
            "navItemsIds"=> nav_items_ids,
            "navItemSelected" => nav_item_selected,
            "marksById" => marks_by_id,
            "boxesById" => boxes_and_plugin_toolbars["boxes"],
            "viewToolbarsById" => view_toolbars_by_id,
            "pluginToolbarsById" => boxes_and_plugin_toolbars["toolbars"],
            "containedViewsById" => contained_views_by_id,
            "exercises" => exercises,
            "isBusy" => ""
        }
    }.to_json
  end
  ## Global Config TODO Finish all metadata
  def self.create_global_config(excursion_json)

    time = excursion_json["TLT"] && excursion_json["TLT"].match(/PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?/)
    age = excursion_json["age_range"] && excursion_json["age_range"].match(/(\d+).+(\d)/)
    {
        "title" => excursion_json["title"],
        "description" => excursion_json["description"],
        "author" => excursion_json["author"] ? excursion_json["author"]["name"] : nil,
        "context" => excursion_json["context"] ? excursion_json["context"].downcase : nil,
        "canvasRatio" => "1.3333333333333333",
        "visorNav" => {
            "player" => true,
            "sidebar" => true,
            "keyBindings" => true
        },
        "trackProgress" => true,
        "age" => {
            "max" => (age && age[2]) ? age[2] : 100,
            "min" => (age && age[1]) ? age[1] : 0,
        },
        # "keywords" => excursion_json["tags"] ? excursion_json["tags"].each_with_index.map{|a,i| {"id":i+1,"text":a }} : [],
        "keywords" => excursion_json["tags"] ? excursion_json["tags"] : [],
        "typicalLearningTime" => {
            "h" => (time && time[1] )? time[1] : 0,
            "m" => (time && time[2] )? time[2] : 0,
            "s" =>  (time && time[3] )? time[3] : 0,
        },
        "version" => '1.0.0',
        "thumbnail" => excursion_json["avatar"],
        "status" => 'draft',
        "structure" => 'linear',
        "difficulty" => excursion_json["difficulty"],
        "allowDownload" => (excursion_json["allow_download"] == true || excursion_json["allow_download"] == "true") ? true : nil,
        "allowClone" => (excursion_json["allow_clone"] == true || excursion_json["allow_clone"] == "true") ? true : nil,
        "allowComments" => (excursion_json["allow_comment"] == true || excursion_json["allow_comment"] == "true") ? true : nil,
        "originalContributors" => excursion_json["contributors"]
    }

  end
  def self.generate_cv_name(i)
    'cv-' + Time.now.to_i.to_s + i.to_s
  end
  def self.generate_nav_item_name(i)
    'pa-' + Time.now.to_i.to_s + i.to_s
  end
  def self.generate_box_name(p,i)
    'bo-' + Time.now.to_i.to_s + '_'+ p.to_s + '_'+ i.to_s
  end
  def self.generate_mark_name(p,i)
    'rm-' + Time.now.to_i.to_s + '_'+ p.to_s + '_' + i.to_s
  end
  def self.get_box_from_element(element)
    {
        "type" => element["type"],
        "body" => element["body"],
        "style" => element["style"],
        "sources" => element["sources"],
        "question" => element["question"],
        "quiztype" => element["quiztype"],
        "choices" => element["choices"],
        "answer" => element["answer"],
        "selfA" => element["selfA"],
        "extras" => element["extras"],
        "contained_views" => element["contained_views"]
    }
  end
  def self.convert_px_to_em(num)
    result = num.delete("px").to_f
    default_font_base = 14
    default_width_base = 1100
    calculatedFontSize = default_font_base * (798) / default_width_base  #px/em in ViSH
    result = result / calculatedFontSize
    result.round(2).to_s + "em"
  end
  def self.convert_sec_to_str(secs)
    t = (secs and secs.to_s.to_i == secs ) ? Time.at(secs.to_i).utc.strftime("%H:%M:%S") : "0"
    t
  end
  def self.generate_names(excursion_json)
    navs_boxes = {}
    cv_boxes = {}
    names = {}
    names_cv = {}
    templates = {}
    plugins = {}
    contained_views = {}
    marks = {}
    cv_marks = {}
    excursion_json["slides"].each_with_index do |slide, p|
      name = generate_nav_item_name(p)
      names[slide["id"]] = name
      navs_boxes[name] = []
      templates[name] = slide["template"]
      type = slide["type"]
      if type === "standard"
        slide["elements"].each_with_index do |element, i|
          box = self.generate_box_name(p,i)
          plugins[box] = self.get_box_from_element(element)
          if plugins[box]["type"]
            navs_boxes[name].push(box)
          else
            navs_boxes[name].push(nil)
          end
        end
      elsif type == "flashcard"
        cvs =  []
        slide["slides"].each_with_index do |slide_cv, q|
          new_cv = self.generate_cv_name(p.to_s + "_" + q.to_s)
          names_cv[slide_cv["id"]] = new_cv
          cv_boxes[new_cv] = []
          cvs.push(new_cv)
          templates[new_cv] = slide_cv["template"]
          slide_cv["elements"].each_with_index do |element, i|
            box = self.generate_box_name(q,(i).to_s + "_f_")
            plugins[box] = self.get_box_from_element(element)
            if plugins[box]["type"]
              cv_boxes[new_cv].push(box)
            else
              cv_boxes[new_cv].push(nil)
            end
          end
        end
        box = self.generate_box_name(p,0)
        slide["pois"].each_with_index do |q, i|
          mark = self.generate_mark_name(p,i)
          cv = names_cv[q["slide_id"]]
          cvs.push(cv)
          x = (q["x"].to_f + 3).to_s
          y = (q["y"].to_f + 8.33).to_s
          value = y + "," + x
          mark_obj = self.create_mark(mark,box,cv,value,i)
          marks[mark] = mark_obj
          if !cv_marks[cv]
            cv_marks[cv] = {}
          end
          cv_marks[cv][mark] = box
        end
        body = slide["background"].match("url.\"(.*)\\\".")
        if body and body.length > 1
          body = body[1]
        end
        plugins[box] = self.get_box_from_element({ "type" => "image", "body" => body, "style" => "", "contained_views"=> cvs })
        navs_boxes[name] = [box]
        templates[name] = "t10"
      elsif type == "VirtualTour"
        cvs =  []
        slide["slides"].each_with_index do |slide_cv, q|
          new_cv = self.generate_cv_name(p.to_s + "_" + q.to_s)
          names_cv[slide_cv["id"]] = new_cv
          cv_boxes[new_cv] = []
          cvs.push(new_cv)
          templates[new_cv] = slide_cv["template"]
          slide_cv["elements"].each_with_index do |element, i|
            box = self.generate_box_name(q,(i).to_s + "_v_")
            plugins[box] = self.get_box_from_element(element)
            if plugins[box]["type"]
              cv_boxes[new_cv].push(box)
            else
              cv_boxes[new_cv].push(nil)
            end
          end
        end
        box = self.generate_box_name(p,0)
        slide["pois"].each_with_index do |q, i|
          mark = self.generate_mark_name(p,i)
          cv = names_cv[q["slide_id"]]
          cvs.push(cv)
          value = q["lat"] + "," + q["lng"]
          mark_obj = self.create_mark(mark,box,cv,value,i)
          marks[mark] = mark_obj
          if !cv_marks[cv]
            cv_marks[cv] = {}
          end
          cv_marks[cv][mark] = box
        end
        plugins[box] = self.get_box_from_element({ "type" => "VirtualTour", "body" => {"center"=> slide["center"], "zoom" => slide["zoom"] }, "style" => "", "contained_views"=> cvs })
        navs_boxes[name] = [box]
        templates[name] = "t2"
      elsif type == "enrichedvideo"
        cvs =  []
        slide["slides"].each_with_index do |slide_cv, q|
          new_cv = self.generate_cv_name(p.to_s + "_" + q.to_s)
          names_cv[slide_cv["id"]] = new_cv
          cv_boxes[new_cv] = []
          cvs.push(new_cv)
          templates[new_cv] = slide_cv["template"]
          slide_cv["elements"].each_with_index do |element, i|
            box = self.generate_box_name(q,(i).to_s + "_e_")
            plugins[box] = self.get_box_from_element(element)
            if plugins[box]["type"]
              cv_boxes[new_cv].push(box)
            else
              cv_boxes[new_cv].push(nil)
            end
          end
        end
        box = self.generate_box_name(p,0)
        slide["pois"].each_with_index do |q, i|
          mark = self.generate_mark_name(p,i)
          cv = names_cv[q["slide_id"]]
          cvs.push(cv)
          value = self.convert_sec_to_str(q["etime"])
          mark_obj = self.create_mark(mark,box,cv,value,i)
          marks[mark] = mark_obj
          if !cv_marks[cv]
            cv_marks[cv] = {}
          end
          cv_marks[cv][mark] = box
        end
        plugins[box] = self.get_box_from_element({ "type" => "video", "body" => slide["video"], "style" => "", "contained_views"=> cvs })
        navs_boxes[name] = [box]
        templates[name] = "t10"
      end
    end
    { "navs_boxes" => navs_boxes, "navs_names" => names, "templates" => templates, "plugins" => plugins, "contained_views" => contained_views, "cv_boxes"=> cv_boxes, "names_cv" => names_cv, "marks" => marks , "cv_marks" => cv_marks}
  end
  def self.create_nav_items_ids(names)
    names.values
  end
  def self.create_nav_item(id, boxes)
    {
        "id" => id,
        "isExpanded" => true,
        "parent" => 0,
        "linkedBoxes" => {},
        "children" => [],
        "boxes" => boxes.compact,
        "level" => 1,
        "type" => "slide",
        "hidden" => false,
        "extraFiles" => {},
        "customSize" => 0
    }
  end
  def self.create_nav_items_by_id(names, boxes_names)
    navs = {}
    names.values.each do |slide|
      boxes = boxes_names[slide]
      navs[slide] = self.create_nav_item(slide, boxes)
    end
    navs["0"] = { "id"=> 0, "children"=> names.values, "boxes"=> [], "level"=> 0, "type"=> '', "hidden"=> false }
    navs
  end
  def self.create_view_toolbar(id,number, isCV, theme)
    bckgTheme = self.themes(theme)
    {
        "id" => id,
        "viewName" => (isCV ? "Contained View " : "Slide " ) + number.to_s,
        "breadcrumb" => 'hidden',
        "courseTitle" => 'hidden',
        "documentSubtitle" => 'hidden',
        "documentSubtitleContent" => '',
        "documentTitle" => 'hidden',
        "documentTitleContent" => "",
        "numPage" => 'hidden',
        "numPageContent" => '',
        "background" => bckgTheme ? bckgTheme["background"] : "#fff",
        "backgroundAttr" => bckgTheme ? bckgTheme["backgroundAttr"] : "cover",
        "aspectRatio" => ""
    }
  end
  def self.create_cv(id, boxes, marks)
    {
        "id" => id,
        "parent" => marks,
        "info" => "new",
        "boxes" => boxes.compact,
        "type" => "slide",
        "extraFiles" => {},
    }
  end
  def self.create_contained_views_by_id(names, boxes_names, cv_marks)
    navs = {}
    names.values.each_with_index do |slide, index|
      boxes = boxes_names[slide]
      navs[slide] = self.create_cv(slide, boxes, cv_marks[slide])
    end
    navs
  end
  def self.create_view_toolbars(names, names_cv, theme)
    navs = {}
    names.values.each_with_index do |slide, i|
      navs[slide] = self.create_view_toolbar(slide, i+1, false, theme)
    end
    names_cv.values.each_with_index do |slide, i|
      navs[slide] = self.create_view_toolbar(slide, i+1, true, theme)
    end
    navs
  end
  def self.create_plugin_toolbar(box, template_box, plugin, box_shape)
    plugin_template = self.convert_plugin(plugin, template_box, box_shape)
    {
        "id" => box,
        "pluginId" => plugin_template["pluginId"],
        "state" => plugin_template["state"],
        "structure" => {
            "height" => template_box["height"] ? template_box["height"] : "auto",
            "width" => template_box["width"],
            "widthUnit" => "%",
            "heightUnit" => "%",
            "rotation" => 0,
            "aspectRatio" => false,
            "position" => box_shape === "relative" ? "relative":"absolute",
        },
        "style" => plugin_template["style"],
        "showTextEditor" => false,

    }
  end
  def self.create_box(box, parent, container, template_box)
    {
        "id" => box,
        "parent" => parent,
        "container" => container,
        "level" => 0,
        "col" => 0,
        "row" => 0,
        "position" => {
            "x" => template_box["x"]+"%",
            "y" => template_box["y"]+"%",
            "type" => container == 0 ? "absolute" : "relative",
        },
        "content" => { },
        "draggable" => true,
        "resizable" => true,
        "showTextEditor" => false,
        "fragment" => {},
        "children" => [],
        "sortableContainers" => {},
        "containedViews" => [ ]
    }
  end
  def self.create_sortable_container(key, children)
    {
        "children" =>children,
        "style" => {
            "padding" =>"0px",
            "borderColor" =>"#ffffff",
            "borderWidth" =>"0px",
            "borderStyle" =>"solid",
            "opacity" =>"1",
            "textAlign" =>"left",
            "className" =>""
        },
        "height" =>"auto",
        "key" => key,
        "colDistribution" =>[100],
        "cols" =>[[100]]
    }
  end
  def self.create_boxes_and_plugin_toolbars(boxes_names, cv_boxes, templates, plugins)
    boxes = {}
    toolbars = {}
    answers = {}
    current_answers = {}
    views = boxes_names.merge(cv_boxes)
    counter = 0
    views.each do|key, boxes_ids|
      template_slide = template(templates[key])["elements"]
      boxes_ids.each_with_index do |box, index|
        if !box.nil?
          box_shape = template_slide.keys[index]
          template_box = template_slide[box_shape]
          toolbars[box] = self.create_plugin_toolbar(box, template_box, plugins[box], box_shape)
          boxes[box] = self.create_box(box, key, 0, template_box)
          if !!toolbars[box]["state"]["__pluginContainerIds"]
            child_states = toolbars[box]["state"]["child_states"]
            answers[box] = toolbars[box]["state"]["right_answers"]
            current_answers[box] =  toolbars[box]["state"]["current_answers"]
            toolbars[box]["state"].delete("child_states")
            toolbars[box]["state"].delete("right_answers")
            toolbars[box]["state"].delete("current_answers")
            boxes[box]["children"] = toolbars[box]["state"]["__pluginContainerIds"].keys
            toolbars[box]["state"]["__pluginContainerIds"].keys.each_with_index do |key_c, ind|
              child = generate_box_name(ind, "__#{index}__#{counter}")
              counter = counter + 1
              boxes[box]["sortableContainers"][key_c] = self.create_sortable_container(key_c, [child])
              text_plugin = child_states[key_c]
              template_box_child = { "x" => "0", "y" => "0", "width" => "100" }
              boxes[child] = self.create_box(child, box, key_c, template_box_child,)
              toolbars[child] = self.create_plugin_toolbar(child, template_box_child, text_plugin, "relative")
            end
          end
        end
      end
    end
    { "boxes" => boxes, "toolbars" => toolbars, "answers" => answers, "current_answers" => current_answers}
  end
  def self.convert_plugin(plugin_template, template_box, box_shape)
    require 'uri'
    pluginId = ""
    state = {}
    style = {
        "borderWidth" => 0,
        "borderStyle" => "solid",
        "borderColor" => "#000000",
        "borderRadius" => box_shape.match("circle") ? "50%": "0",
        "opacity" => 1,
    }
    case plugin_template["type"]
    when "image"
      pluginId = "HotspotImages"
      styled = plugin_template["style"] || ""
      width = styled.match("width\:(.*?)\%\;")
      width_is_defined = (width and width.length > 1)
      width = width_is_defined ? width[1].to_f : 100

      height = styled.match("height\:(.*?)\%\;")
      height_is_defined = (height and height.length > 1)
      height = height_is_defined ? height[1].to_f : 100

      left = styled.match("left\:(.*?)\%\;")
      left = (left and left.length > 1) ? left[1].to_f : 0
      top = styled.match("top\:(.*?)\%\;")
      top = (top and top.length > 1) ? top[1].to_f : 0
      top =  top*100/height
      scale = width_is_defined ? (width.to_f/100).round(2) : (height.to_f/100).round(2)
      state = {
          "url" => plugin_template["body"],
          "translate" => {
              "x" => left,
              "y" => top * scale
          },
          "scale" => scale,
          "allowDeformed" => !!plugin_template["contained_views"]

      }
    when "text"
      pluginId = "BasicText"
      text = plugin_template["body"]
      result = text.gsub(/([0-9]\d*(\.\d+)?)px/) { |num| (self.convert_px_to_em(num))}
      state = { "__text" => URI::encode("<div>"+ URI::decode(result)+"</div>").gsub(/%23/,'#') }
      style["padding"] = 7
      style["backgroundColor"] = "rgba(255,255,255,0)"
    when "object"
      if (plugin_template["body"].match("youtube"))
        pluginId = "EnrichedPlayer"
        url = plugin_template["body"].match("src=\\\"(.+?)\\\"")
        state = { "url" => (url && url[1]) ? url[1] : "", "controls" => true}
      elsif (plugin_template["body"].match("\.pdf\\\""))
        pluginId = "EnrichedPDF"
        url = plugin_template["body"].match("src=\\\"(.+?)\\\"")
        state = { "url" => (url && url[1]) ? url[1] : "", "numPages" => nil, "pageNumber" => "1"}
      elsif (plugin_template["body"].match("scorm"))
        pluginId = "ScormPackage"
        url = plugin_template["body"].match("src=\\\"(.+?)\\\"")
        state = { "url" => (url && url[1]) ? url[1] : ""}
      elsif (plugin_template["body"].match("\\u003Cembed"))
        pluginId = "FlashObject"
        url = plugin_template["body"].match("src=\\\"(.+?)\\\"")
        state = { "url" => (url && url[1]) ? url[1] : ""}
      else
        pluginId = "Webpage"
        url = plugin_template["body"].match("src=\\\"(.+?)\\\"")
        state = { "url" => (url && url[1]) ? url[1] : "" }
      end
    when "audio"
      pluginId = "EnrichedAudio"
      url = plugin_template["sources"].match("src\\\":\\\"(.*?)\\\"")
      state = { "url" => (url && url[1]) ? url[1] : "", "autoplay" => false, "controls" => true, "waves" => true, "barWidth" => 2, "progressColor" => "#ccc", "waveColor" => "#178582", "scroll" => false}
    when "video"
      pluginId = "EnrichedPlayer"
      url = ""
      if plugin_template["sources"]
        url = plugin_template["sources"].match("src\\\":\\\"(.*?)\\\"")
        url = (url && url[1]) ? url[1] : ""
      elsif plugin_template["body"] and plugin_template["body"]["source"]
        url = plugin_template["body"]["source"]
      end

      state = { "url" => url, "controls" => true}
    when "VirtualTour"
      pluginId = "VirtualTour"
      body = plugin_template["body"]
      state = { "config" => {"lat" => body["center"]["lat"].to_f, "lng" => body["center"]["lng"].to_f, "zoom" => body["zoom"].to_f}}
    when "quiz"
      case plugin_template["quiztype"]
      when "multiplechoice"
        isMA = plugin_template["extras"]["multipleAnswer"]
        pluginId =  isMA ? "MultipleAnswer" : "MultipleChoice"
        question = plugin_template["question"]
        answers = plugin_template["choices"]
        child_states = {
            "sc-Question" => { "type" => "text", "body" => question["wysiwygValue"] || question["value"] }
        }
        plugin_container_ids = {
            "sc-Question" => { "id" => "sc-Question", "name" => "Question", "height" => "auto" }
        }
        right_answer = isMA ? [] : ""
        answers.each_with_index do |ans, i|
          ind = i
          plugin_container_ids["sc-Answer#{ind}"] = { "id" => "sc-Answer#{ind}", "name" => "Answer #{ind}", "height" => "auto" }
          child_states["sc-Answer#{ind}"] = { "type" => "text", "body" => ans["wysiwygValue"] || ans["value"] }
          if ans["answer"]
            if isMA
              right_answer.push(i)
            else
              right_answer = i
            end
          end

        end
        plugin_container_ids["sc-Feedback"] = { "id" => "sc-Feedback", "name" => "Feedback", "height"=> "auto"}
        child_states["sc-Feedback"] =  { "type" => "text", "body" => ""}
        style["padding"] = 10
        style["borderWidth"] = 0
        style["borderColor"] = "#dbdbdb"
        state = {
            "nBoxes" => answers.length,
            "showFeedback" => false,
            "letters" => "Letters",
            "quizColor" => "rgba(0, 173, 156, 1)",
            "__pluginContainerIds" => plugin_container_ids,
            "child_states" => child_states,
            "right_answers" => right_answer,
            "current_answers" => "",

        }
      when "truefalse"
        pluginId =  "TrueFalse"
        question = plugin_template["question"]
        answers = plugin_template["choices"]
        right_answer = []
        child_states = {
            "sc-Question" => { "type" => "text", "body" => question["wysiwygValue"] || question["value"] }
        }
        plugin_container_ids = {
            "sc-Question" => { "id" => "sc-Question", "name" => "Question", "height" => "auto" }
        }
        answers.each_with_index do |ans, ind|
          plugin_container_ids["sc-Answer#{ind}"] = { "id" => "sc-Answer#{ind}", "name" => "Answer #{ind}", "height" => "auto" }
          child_states["sc-Answer#{ind}"] = { "type" => "text", "body" => ans["wysiwygValue"] || ans["value"] }
          right_answer.push(!!ans["answer"])
        end
        plugin_container_ids["sc-Feedback"] = { "id" => "sc-Feedback", "name" => "Feedback", "height"=> "auto"}
        child_states["sc-Feedback"] =  { "type" => "text", "body" => ""}
        style["padding"] = 10
        style["borderWidth"] = 0
        style["borderColor"] = "#dbdbdb"
        state = {
            "nBoxes" => answers.length,
            "showFeedback" => false,
            "letters" => "Letters",
            "quizColor" => "rgba(0, 173, 156, 1)",
            "__pluginContainerIds" => plugin_container_ids,
            "child_states" => child_states,
            "right_answers" => right_answer.map { |n| n.to_s },
            "current_answers" => right_answer.map { |n| "" }
        }
      when "openAnswer"
        pluginId =  "FreeResponse"
        question = plugin_template["question"]
        child_states = {
            "sc-Question" => { "type" => "text", "body" => question["wysiwygValue"] || question["value"] },
            "sc-Feedback" => { "type" => "text", "body" => ""}
        }
        plugin_container_ids = {
            "sc-Question" => { "id" => "sc-Question", "name" => "Question", "height" => "auto" },
            "sc-Feedback" => { "id" => "sc-Feedback", "name" => "Feedback", "height" => "auto" }
        }
        style["padding"] = 10
        style["borderWidth"] = 0
        style["borderColor"] = "#dbdbdb"
        state = {
            "showFeedback" => false,
            "quizColor" => "rgba(0, 173, 156, 1)",
            "characters" => true,
            "correct"=> plugin_template["selfA"],
            "__pluginContainerIds" => plugin_container_ids,
            "child_states" => child_states,
            "right_answers" => plugin_template["answer"]["value"],
            "current_answers" => "",
        }
      when "sorting"
        pluginId =  "Ordering"
        question = plugin_template["question"]
        answers = plugin_template["choices"]
        right_answer = nil
        child_states = {
            "sc-Question" => { "type" => "text", "body" => question["wysiwygValue"] || question["value"] }
        }
        plugin_container_ids = {
            "sc-Question" => { "id" => "sc-Question", "name" => "Question", "height" => "auto" }
        }
        answers.each_with_index do |ans, ind|
          plugin_container_ids["sc-Answer#{ind}"] = { "id" => "sc-Answer#{ind}", "name" => "Answer #{ind}", "height" => "auto" }
          child_states["sc-Answer#{ind}"] = { "type" => "text", "body" => ans["wysiwygValue"] || ans["value"] }
        end
        plugin_container_ids["sc-Feedback"] = { "id" => "sc-Feedback", "name" => "Feedback", "height"=> "auto"}
        child_states["sc-Feedback"] =  { "type" => "text", "body" => ""}
        style["padding"] = 10
        style["borderWidth"] = 0
        style["borderColor"] = "#dbdbdb"
        state = {
            "nBoxes" => answers.length,
            "showFeedback" => false,
            "letters" => "Letters",
            "quizColor" => "rgba(0, 173, 156, 1)",
            "__pluginContainerIds" => plugin_container_ids,
            "child_states" => child_states,
            "right_answers" => nil,
            "current_answers" => ""
        }
      end
    else
      pluginId = "HotspotImages"
      state = { "url" => "https://via.placeholder.com/350x150" }
    end
    { "pluginId" => pluginId, "state" => state , "style" => style}
  end
  def self.create_mark(mark, box, cv, value, n)
    {
        "id"=> mark,
        "origin"=> box,
        "title"=> "New mark " + (n+1).to_s,
        "connection"=> cv,
        "connectMode"=> "new",
        "displayMode" => "navigate",
        "value" => value
    }
  end
  def self.create_exercise(name, box, answer, current_answer)
    {
        "name" => name,
        "id" => box,
        "weight" => 1,
        "correctAnswer" => answer,
        "currentAnswer" => current_answer,
        "attempted" => false,
        "score" => 0,
        "quizColor" => "rgba(11,255,255,1)",
        "correct" => false
    }
  end
  def self.create_exercises( nav_names, cv_names, plugin_toolbars_by_id, answers, current_answers)
    exercises = {}
    views = nav_names.merge(cv_names)
    views.each do|key, boxes|
      ex_boxes = {}
      boxes.each do |box|
        if !box.nil?
          plugin = plugin_toolbars_by_id[box]
          if  ["MultipleChoice", "MultipleAnswer", "InputText", "Ordering", "ScormPackage", "FreeResponse", "TrueFalse"].include? plugin["pluginId"]
            ex_boxes[box] = create_exercise( plugin["pluginId"], box, answers[box], current_answers[box] )
          end
        end
      end
      exercises[key] =  {
          "id" => key,
          "submitButton" => true,
          "trackProgress" => false,
          "attempted" => false,
          "weight" => 10,
          "minForPass" => 50,
          "exercises" => ex_boxes,
          "score" => 0,
      }
    end
    exercises
  end
  def self.template(id)
    templates = {
        "t1" => {
            "elements" => {
                "left" => {
                    "x" => "20",
                    "y" => "5",
                    "width" => "60",
                    "height" => "66"
                },
                "header" => {
                    "x" => "20",
                    "y" => "74",
                    "width" => "60",
                    "height" => "13"
                },
                "subheader" => {
                    "x" => "20",
                    "y" => "89.5",
                    "width" => "60",
                    "height" => "5.5"
                },
            }
        },
        "t2" => {
            "elements" => {
                "left" => {
                    "x" => "5",
                    "y" => "5",
                    "width" => "90",
                    "height" => "90"
                },
            }
        },
        "t3" => {
            "elements" => {
                "header" => {
                    "x" => "5",
                    "y" => "5",
                    "width" => "90",
                    "height" => "9",
                },
                "left" => {
                    "x" => "5",
                    "y" => "16",
                    "width" => "90",
                    "height" => "78",
                },

            }
        },
        "t4" => {
            "elements" => {
                "header" => {
                    "x" => "5",
                    "y" => "5",
                    "width" => "90",
                    "height" => "9",
                },
                "left" => {
                    "x" => "5",
                    "y" => "16",
                    "width" => "90",
                    "height" => "59",
                },
                "right" => {
                    "x" => "5",
                    "y" => "77",
                    "width" => "90",
                    "height" => "21.2",
                }
            }
        },
        "t5" => {
            "elements" => {
                "header" => {
                    "x" => "5",
                    "y" => "5",
                    "width" => "90",
                    "height" => "9",
                },
                "left" => {
                    "x" => "5",
                    "y" => "16",
                    "width" => "44",
                    "height" => "78",
                },
                "right" => {
                    "x" => "50.5",
                    "y" => "16",
                    "width" => "44",
                    "height" => "78",
                },
            }
        },
        "t17" => {
            "elements" => {
                "header" => {
                    "x" => "5",
                    "y" => "5",
                    "width" => "90",
                    "height" => "9",
                },
                "left" => {
                    "x" => "5",
                    "y" => "16",
                    "width" => "56.6",
                    "height" => "78",
                },
                "right" => {
                    "x" => "64",
                    "y" => "16",
                    "width" => "31",
                    "height" => "78",
                },
            }
        },
        "t16" => {
            "elements" => {
                "header" => {
                    "x" => "5",
                    "y" => "5",
                    "width" => "90",
                    "height" => "9",
                },
                "left" => {
                    "x" => "5",
                    "y" => "16",
                    "width" => "30",
                    "height" => "78",
                },
                "right" => {
                    "x" => "36.5",
                    "y" => "16",
                    "width" => "58.5",
                    "height" => "78",
                },
            }
        },
        "t20" => {
            "elements" => {
                "header" => {
                    "x" => "5",
                    "y" => "5",
                    "width" => "90",
                    "height" => "9",
                },
                "left" => {
                    "x" => "5",
                    "y" => "16",
                    "width" => "58",
                    "height" => "78",
                },
                "right1" => {
                    "x" => "65",
                    "y" => "16",
                    "width" => "30",
                    "height" => "37",
                },
                "right2" => {
                    "x" => "65",
                    "y" => "55",
                    "width" => "30",
                    "height" => "37",
                },
            }
        },
        "t8" => {
            "elements" => {
                "header" => {
                    "x" => "5",
                    "y" => "5",
                    "width" => "90",
                    "height" => "9",
                },
                "left" => {
                    "x" => "5",
                    "y" => "16",
                    "width" => "30",
                    "height" => "37",
                },
                "center" => {
                    "x" => "5",
                    "y" => "55",
                    "width" => "30",
                    "height" => "41.8",
                },
                "right" => {
                    "x" => "37",
                    "y" => "16",
                    "width" => "58",
                    "height" => "81.2",
                },
            }
        },
        "t7" => {
            "elements" => {
                "header" => {
                    "x" => "5",
                    "y" => "5",
                    "width" => "90",
                    "height" => "9",
                },
                "left" => {
                    "x" => "5",
                    "y" => "16",
                    "width" => "30",
                    "height" => "81.2",
                },
                "center" => {
                    "x" => "38",
                    "y" => "16",
                    "width" => "57",
                    "height" => "67",
                },
                "subheader" => {
                    "x" => "38",
                    "y" => "86",
                    "width" => "57",
                    "height" => "11",
                },
            }
        },
        "t6" => {
            "elements" => {
                "header" => {
                    "x" => "5",
                    "y" => "5",
                    "width" => "90",
                    "height" => "9",
                },
                "left" => {
                    "x" => "5",
                    "y" => "16",
                    "width" => "28",
                    "height" => "80",
                },
                "center" => {
                    "x" => "34.5",
                    "y" => "16",
                    "width" => "30.5",
                    "height" => "80",
                },
                "right" => {
                    "x" => "67",
                    "y" => "16",
                    "width" => "28",
                    "height" => "80",
                },
            }
        },
        "t9" => {
            "elements" => {
                "header" => {
                    "x" => "5",
                    "y" => "5",
                    "width" => "90",
                    "height" => "9",
                },
                "left" => {
                    "x" => "5",
                    "y" => "16",
                    "width" => "56",
                    "height" => "37",
                },
                "center" => {
                    "x" => "63.3",
                    "y" => "16",
                    "width" => "30.5",
                    "height" => "80",
                },
                "right" => {
                    "x" => "5",
                    "y" => "55.35",
                    "width" => "56",
                    "height" => "41.5",
                },
            }
        },
        "t12" => {
            "elements" => {
                "left1" => {
                    "x" => "3",
                    "y" => "5",
                    "width" => "45",
                    "height" => "43",
                },
                "right1" => {
                    "x" => "51",
                    "y" => "5",
                    "width" => "45",
                    "height" => "43",
                },
                "left2" => {
                    "x" => "3",
                    "y" => "52",
                    "width" => "45",
                    "height" => "43",
                },
                "right2" => {
                    "x" => "51",
                    "y" => "52",
                    "width" => "45",
                    "height" => "43",
                },
            }
        },
        "t15" => {
            "elements" => {
                "left" => {
                    "x" => "5",
                    "y" => "4",
                    "width" => "27",
                    "height" => "32",
                },
                "center" => {
                    "x" => "36",
                    "y" => "4",
                    "width" => "28",
                    "height" => "32",
                },
                "right" => {
                    "x" => "67",
                    "y" => "4",
                    "width" => "28",
                    "height" =>"32",
                },
                "center2" => {
                    "x" => "5",
                    "y" => "40",
                    "width" => "90",
                    "height" => "55",
                },
            }
        },
        "t11" => {
            "elements" => {
                "center1" => {
                    "x" => "5",
                    "y" => "4",
                    "width" => "90",
                    "height" => "28.4",
                },
                "center2" => {
                    "x" => "5",
                    "y" => "36",
                    "width" => "90",
                    "height" => "28.4",
                },
                "center3" => {
                    "x" => "5",
                    "y" => "68",
                    "width" => "90",
                    "height" => "28.4",
                },
            }
        },
        "t14" => {
            "elements" => {
                "circle1" => {
                    "x" => "5",
                    "y" => "6.35",
                    "width" => "19.8",
                    "height" => "26.4",
                },
                "right1" => {
                    "x" => "29.6",
                    "y" => "6.35",
                    "width" => "64",
                    "height" => "25.7",
                },
                "circle2" => {
                    "x" => "5",
                    "y" => "38.5",
                    "width" => "19.8",
                    "height" => "26.4",
                },
                "right2" => {
                    "x" => "29.6",
                    "y" => "38.5",
                    "width" => "64",
                    "height" => "25.7",
                },
                "circle3" => {
                    "x" => "5",
                    "y" => "70.5",
                    "width" => "19.8",
                    "height" => "26.4",
                },
                "right3" => {
                    "x" => "29.6",
                    "y" => "70.5",
                    "width" => "64",
                    "height" => "25.7",
                },
            }
        },
        "t13" => {
            "elements" => {
                "header" => {
                    "x" => "5",
                    "y" => "4",
                    "width" => "90",
                    "height" => "9.2",
                },
                "circle" => {
                    "x" => "5",
                    "y" => "17",
                    "width" => "43",
                    "height" => "56",
                },
                "left" => {
                    "x" => "52",
                    "y" => "17",
                    "width" => "43.2",
                    "height" => "79",
                },
                "right" => {
                    "x" => "5",
                    "y" => "82.8",
                    "width" => "43.2",
                    "height" => "13.7",
                },
            }
        },
        "t10" => {
            "elements" => {
                "center" => {
                    "x" => "0",
                    "y" => "0",
                    "width" => "100",
                    "height" => "100",
                },
            }
        },
        "t18" => {
            "elements" => {
                "header" => {
                    "x" => "0",
                    "y" => "0",
                    "width" => "100",
                    "height" => "6.35",
                },
                "center" => {
                    "x" => "0",
                    "y" => "6.35",
                    "width" => "100",
                    "height" => "93.65",
                },
            }
        },
        "t19" => {
            "elements" => {
                "header" => {
                    "x" => "0",
                    "y" => "0",
                    "width" => "100",
                    "height" => "6.35",
                },
                "center" => {
                    "x" => "0",
                    "y" => "6.35",
                    "width" => "100",
                    "height" => "87.65",
                },
                "bottom" => {
                    "x" => "0",
                    "y" => "94",
                    "width" =>"100",
                    "height" => "6",
                },
            }
        },

    }

    templates[id]
  end
  def self.themes(id)
    themeList = {
        "theme1"=> {
            "background" => "rgb(255,255,255)",
            "backgroundAttr" => "full",
        },
        "theme13"=> {
            "background" => "rgb(87,87,87)",
            "backgroundAttr" => "full",
        },
        "theme14"=> {
            "background" => "https://vishub.org/assets/themes/theme14/bg.jpg",
            "backgroundAttr" => "full",
        },
        "theme15"=> {
            "background" => "rgb(17,17,17)",
            "backgroundAttr" => "full",
        },
        "theme16"=> {
            "background" => "https://vishub.org/assets/themes/theme16/bg.jpg",
            "backgroundAttr" => "full",
        },
        "theme17"=> {
            "background" => "https://vishub.org/assets/themes/theme17/bg.jpg",
            "backgroundAttr" => "full",
        },
        "theme18"=> {
            "background" => "https://vishub.org/assets/themes/theme18/bg.jpg",
            "backgroundAttr" => "full",
        },
        "theme19"=> {
            "background" => "https://vishub.org/assets/themes/theme19/bg.jpg",
            "backgroundAttr" => "full",
        },
        "theme20"=> {
            "background" => "https://vishub.org/assets/themes/theme20/bg.jpg",
            "backgroundAttr" => "full",
        },
        "theme21"=> {
            "background" => "https://vishub.org/assets/themes/theme21/bg.jpg",
            "backgroundAttr" => "full",
        },
        "theme22"=> {
            "background" => "https://vishub.org/assets/themes/theme22/bg.jpg",
            "backgroundAttr" => "full",
        },
        "theme23"=> {
            "background" => "https://vishub.org/assets/themes/theme23/bg.jpg",
            "backgroundAttr" => "full",
        },

    }
    themeList[id]
  end
end