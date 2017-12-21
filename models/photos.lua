local to_json = require("lapis.util").to_json
local db = require "lapis.db"
local Model = require("lapis.db.model").Model
local Photos = Model:extend("photos")

local split = require "utils.split"

Photos.img_path = "./build/img/" 

function Photos:getMainScreen() 
  return self:select("where is_main=1")
end

function Photos:getPhoto(id) 
  local photo = self:find(id)
  
  return photo
end 

function Photos:getPhotos(category_id)
  local photos = {}

  if category_id then 
    photos = self:select(
      "where category_id=?", 
      category_id, 
      {fields = "src, id, caption, title, width, height"}
    )
  else 
    photos = self:select(
      nil, 
      nil, 
      {fields = "thumbnail as src, id, caption, title"}
    )
  end

  return photos
end

function Photos:uploadPhoto(file, info)
  local magick = require("magick.wand")
  local type = file["content-type"]
  local mimeType = split(type, "/")[2]
  local image = magick.load_image_from_blob(file.content)
  local thumb = magick.load_image_from_blob(file.content)

  thumb:scale(nil, 400)
  thumb:set_quality(100)
  
  local photo = self:create {
      title = info.name,
      is_main = info.main,
      category_id = info.category_id,
      caption = info.caption,
      width = thumb:get_width(),
      height = thumb:get_height()
    }
  local thumbPath = info.category_id 
                    .. "/" 
                    .. info.name .. "_" 
                    .. photo.id
                    .. "_thumb"
                    .. "." .. mimeType
  local filePath = info.category_id 
                    .. "/" 
                    .. info.name .. "_" 
                    .. photo.id
                    .. "." .. mimeType

  db.query("UPDATE photos SET src = ?, thumbnail = ? WHERE id = ?", 
    "/img/" .. filePath, "/img/" .. thumbPath, photo.id)
  
  image:write(self.img_path .. filePath)
  thumb:write(self.img_path .. thumbPath)

  return photo
end

function Photos:deletePhoto(photo) 

  local deleted = self:find(photo.id)
  deleted:delete()
  print("deleted", deleted)
  os.remove("./build" .. photo.src)
  
  return deleted
end


return Photos
