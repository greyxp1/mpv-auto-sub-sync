local mp = require "mp"
local utils = require "mp.utils"
local command, source, output
local generation = 0
local prefix = ("%s/mpv-auto-sub-sync-%d-"):format(
  os.getenv("XDG_RUNTIME_DIR") or "/tmp", utils.getpid())

local function remove_source(path)
  if path then os.remove(path) end
  if source == path then source = nil end
end

local function stop()
  generation = generation + 1
  if command then mp.abort_async_command(command); command = nil end
  remove_source(source)
  if output then os.remove(output); output = nil end
end

local function selected_subtitle()
  local secondary = mp.get_property_native("secondary-sid")
  local fallback = {}
  for _, track in ipairs(mp.get_property_native("track-list") or {}) do
    if track.type == "sub" and track.id ~= secondary then
      local path, ext, stream
      if track.external then
        path = track["external-filename"]
        ext = path and path:match("%.([^./]+)$")
        ext = ext and ext:lower()
        if ext ~= "srt" and ext ~= "ass" and ext ~= "ssa" then ext = nil end
      else
        ext = ({subrip = "srt", ass = "ass", ssa = "ass"})[track.codec]
        stream = track["ff-index"]
        if not stream then ext = nil end
      end
      if ext then
        if track.selected then return path, ext, stream end
        if not fallback[2] then fallback = {path, ext, stream} end
      end
    end
  end
  return fallback[1], fallback[2], fallback[3]
end

local function selected_audio()
  local index = 0
  for _, track in ipairs(mp.get_property_native("track-list") or {}) do
    if track.type == "audio" then
      if track.selected then return "0:a:" .. index end
      index = index + 1
    end
  end
end

local function align(media, subtitle, ext, audio, token, temporary)
  local result = prefix .. token .. "." .. ext

  command = mp.command_native_async({
    name = "subprocess", playback_only = true,
    capture_stdout = true, capture_stderr = true,
    args = {"ffsubsync", media, "-i", subtitle, "-o", result,
      "--reference-stream", audio},
  }, function(success, response)
    remove_source(temporary)
    if token ~= generation then os.remove(result); return end
    command = nil
    if not success or not response or response.status ~= 0 or mp.get_property("path") ~= media then
      os.remove(result)
      mp.msg.warn("Automatic subtitle synchronization failed")
      return
    end
    if mp.commandv("sub-add", result, "select", "auto-synced") then
      output = result
      mp.set_property_number("sub-delay", 0)
      mp.osd_message("Subtitles synchronized")
    else
      os.remove(result)
    end
  end)
end

local function sync()
  local media = mp.get_property("path")
  local subtitle, ext, stream = selected_subtitle()
  local audio = selected_audio()
  if not media or media:match("^%a[%w+.-]*://") or not ext or not audio then return end

  generation = generation + 1
  local token = generation
  if subtitle then align(media, subtitle, ext, audio, token); return end

  source = prefix .. token .. "-source." .. ext
  local current_source = source
  command = mp.command_native_async({
    name = "subprocess", playback_only = true,
    args = {"ffmpeg", "-v", "error", "-y", "-i", media,
      "-map", "0:" .. stream, "-c:s", "copy", current_source},
  }, function(success, response)
    if token ~= generation then remove_source(current_source); return end
    command = nil
    if not success or not response or response.status ~= 0 then
      remove_source(current_source)
      mp.msg.warn("Could not extract subtitle for automatic synchronization")
      return
    end
    align(media, current_source, ext, audio, token, current_source)
  end)
end

mp.register_event("end-file", stop)
mp.register_event("file-loaded", sync)
