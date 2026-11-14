local config = require("mip.config")
local B = require("mip.backend")

--- Images uploaded to the terminal, keyed by raster entry + cell size.
local Store = { imgs = {}, count = 0 }

function Store.get(ent, cols, rows)
  local backend = B.current
  local k = ("%s:%dx%d"):format(ent.key or ent.hash, cols, rows)
  local img = Store.imgs[k]
  if not img then
    img = { k = k, id = backend.new_id(), path = ent.path, cols = cols, rows = rows }
    img.hl = "MIPImg" .. img.id
    img.texts = backend.texts(img)
    backend.upload(img)
    Store.imgs[k] = img
    Store.count = Store.count + 1
  end
  return img
end

--- Free images no buffer currently references. `live` is a set of keys.
function Store.prune(live)
  if Store.count <= config.values.max_images then return end
  for k, img in pairs(Store.imgs) do
    if not live[k] then
      B.current.free(img)
      Store.imgs[k] = nil
      Store.count = Store.count - 1
    end
  end
end

function Store.clear()
  if B.current then
    for _, img in pairs(Store.imgs) do B.current.free(img) end
  end
  Store.imgs, Store.count = {}, 0
end

return Store
