local LrApplication = import("LrApplication")
local LrDialogs = import("LrDialogs")
local LrFunctionContext = import("LrFunctionContext")
local LrErrors = import("LrErrors")
local LrFileUtils = import("LrFileUtils")
local LrPathUtils = import("LrPathUtils")
local LrTasks = import("LrTasks")
local LrLogger = import("LrLogger")
local LrProgressScope = import("LrProgressScope")
local LrColor = import("LrColor")
local LrHttp = import("LrHttp")

local prefs = import("LrPrefs").prefsForPlugin() -- plugins own preferences
local myLogger = LrLogger("VideoRenderer")

--myLogger:enable("logfile")
myLogger:enable("print")

--------------------------------------------------------------------------------

-- resize images
-- https://alexthejourno.com/2014/03/time-lapse-simplified-in-a-script/
-- x=1
--for i in *.jpg; do
--	counter=$(printf %06d $x)
--	convert "$i" -resize "$vwidth"x"$vheight"^ -gravity "$img_gravity" -crop "$vwidth"x"$vheight"+0+0 +repage resized/img"$counter".jpg
--	x=$(($x+1))
--done

local exportServiceProvider = {}

exportServiceProvider.allowFileFormats = { 'JPEG' }
exportServiceProvider.allowColorSpaces = { 'sRGB' }
exportServiceProvider.showSections = { 'exportLocation' }
-- exportServiceProvider.canExportToTemporaryLocation = true

exportServiceProvider.updateExportSettings = function ( exportSettings )

	exportSettings.LR_outputSharpeningOn = true
	exportSettings.LR_outputSharpeningMedia = 'screen'
	exportSettings.LR_outputSharpeningLevel = 2 -- medium
	
	-- exportSettings.LR_export_useSubfolder = 'false'
	exportSettings.LR_collisionHandling = 'ask'
	exportSettings.LR_extensionCase = 'lowercase'
	exportSettings.LR_renamingTokensOn = true
	exportSettings.LR_initialSequenceNumber = 1
	exportSettings.LR_tokens = '{{naming_sequenceNumber_5Digits}}'
	exportSettings.LR_jpeg_quality = 1

end

exportServiceProvider.exportPresetFields = {
		{ key = 'filename', default = 'video.mp4' },
		{ key = 'codec', default = 'libx264' },
		{ key = 'container', default = 'mp4' },
		{ key = 'size', default = '1920x1080' },
		{ key = 'framerate', default = '30' },
		{ key = 'pixelFormat', default = 'yuv420p' },
		-- -aspect aspect      set aspect ratio (4:3, 16:9 or 1.3333, 1.7777)
}

exportServiceProvider.startDialog = function ( propertyTable )

    myLogger:trace("startDialog")
    --local updateChecker = require('UpdateChecker')
    --updateChecker.check()
	
end

exportServiceProvider.sectionsForTopOfDialog = function ( f , propertyTable )
	return {
		{
			title = 'Information',
			f:column {
				f:static_text {title = 'Author: Andreas Hermann <a.v.hermann@gmail.com>'},
				f:spacer {height = 10},
				f:static_text {title = 'This plugin includes these third-party tools:'},
				f:row {
					f:static_text {title = '- ffmpeg'},
					f:static_text {
						title = 'https://www.ffmpeg.org/',
						mouse_down = function() LrHttp.openUrlInBrowser('https://www.ffmpeg.org/') end,
						text_color = LrColor( 0, 0, 1 )
					}
				},
				f:row {
					f:static_text {title = '- ImageMagick®'},
					f:static_text {
						title = 'http://www.imagemagick.org/',
						mouse_down = function() LrHttp.openUrlInBrowser('http://www.imagemagick.org/') end,
						text_color = LrColor( 0, 0, 1 )
					}
				}
			}
		}
	}
end

exportServiceProvider.sectionsForBottomOfDialog = function ( _, propertyTable )

	local LrView = import 'LrView'

	local f = LrView.osFactory()
	local bind = LrView.bind
	local share = LrView.share
	
	--local photo = catalog:getTargetPhoto()
	--photo:requestJpegThumbnail(320,240,function(data,err)
	--	
	--end)
	--local dim = photo:getRawMetadata("croppedDimensions")
	--local aspect = aspectRatio
	local catalog = LrApplication.activeCatalog()
	local targetPhoto = catalog:getTargetPhoto()
	
	-- needs to run in LrTask
	--local croppedDimensions = ".x."
	--LrTasks.startAsyncTask(function() 
	--	croppedDimensions = targetPhoto:getFormattedMetadata("croppedDimensions")
	--end)

	local result = {
		{
			title = LOC "$$$/VideoRenderer/ExportDialog/VideoSettings=Render Settings",
			synopsis = bind { key = 'fullPath', object = propertyTable },
			
			--f:row {
			--	f:static_text {
			--		title = LOC "$$$/VideoRenderer/ExportDialog/Size=Original Image:",
			--		alignment = 'right',
			--		width = share 'leftLabel',
			--	},
			--	f:catalog_photo({
			--		photo = targetPhoto,
			--		width = 320,
			--		height = 240,
			--	})
			--},
			
			f:row {
				f:static_text {
					title = LOC "$$$/VideoRenderer/ExportDialog/Size=Size:",
					alignment = 'right',
					width = share 'leftLabel',
				},
				
				f:popup_menu {
					value = bind 'size',
					items = {
						{ value = '3840x2160', title = "4K - 3840x2160" },
						{ value = '2704x1524', title = "2.7K - 2704x1524" },
						{ value = '1920x1080', title = "Full HD - 1920x1080" },
						{ value = '1280x720', title = "HD - 1280x720" },
						{ value = '640x480', title = "VGA - 640x480" },
					},
					-- Standard 4:3: 320x240, 640x480, 800x600, 1024x768
					-- Widescreen 16:9: 640x360, 800x450, 960x540, 1024x576, 1280x720, and 1920x1080
				},
				
				--f:static_text {
				--	title = LOC "$$$/VideoRenderer/ExportDialog/SourceSizeLabel=Source:",
				--	alignment = 'right',
				--	width = share 'leftLabel',
				--},
				--
				--f:static_text {
				--	title = croppedDimensions,
				--	alignment = 'right',
				--	width = share 'leftLabel'
				--},
			},
			
			f:row {
				f:static_text {
					title = LOC "$$$/VideoRenderer/ExportDialog/Codec=Video Format:",
					alignment = 'right',
					width = share 'leftLabel',
				},
				
				f:popup_menu {
					value = bind 'codec',
					items = {
						{ value = 'libx264', title = "H.264" },
						--{ value = 'libx265', title = "H265/HVEC (Experimental)" },
						--{ value = 'prores', title = "Apple ProRes" },
						--{ value = 'gif', title = "GIF" },
    					-- extensionForFormat
					},
				},
			},
			
			f:row {
				f:static_text {
					title = LOC "$$$/VideoRenderer/ExportDialog/FrameRate=Frame Rate:",
					alignment = 'right',
					width = share 'leftLabel',
				},
				
				f:popup_menu {
					value = bind 'framerate',
					items = {
						{ value = '25', title = "25 Frames/s" },
						{ value = '30', title = "30 Frames/s" },
						{ value = '48', title = "48 Frames/s" },
						{ value = '60', title = "60 Frames/s" },
					},
				},
			},
			
			f:row {
				f:static_text {
					title = LOC "$$$/VideoRenderer/ExportDialog/FileName=File Name:",
					alignment = 'right',
					width = share 'leftLabel',
				},

				f:edit_field {
					value = bind 'filename',
					truncation = 'middle',
					immediate = true,
					fill_horizontal = 1,
				},
			}
		}
	}
	
	return result
	
end

function exportServiceProvider.processRenderedPhotos( functionContext, exportContext )
	myLogger:trace("Start exportServiceProvider.processRenderedPhotos")
	
	local exportSession = exportContext.exportSession
	local exportParams = exportContext.propertyTable
    
    local numPhotos = exportSession:countRenditions()
    local progressScope = exportContext:configureProgress({
      title = LOC("$$$/VideoRenderer/ProgressExport=Exporting ^1 Images for Video Renderer", numPhotos)
    })
    
    local files = {}
    numFiles = 0
    for i, rendition in exportContext:renditions({stopIfCanceled = true, progressScope = progressScope, renderProgressPortion = 0.5}) do
      local success, pathOrMessage = rendition:waitForRender()
      if progressScope:isCanceled() then
        break
      end
      if success then
        numFiles = numFiles + 1
        local parent = LrPathUtils.parent(rendition.destinationPath)
        local resizedFile = rendition.destinationPath 
        -- resizedFile = LrPathUtils.child(parent,string.format("%i_resized.jpg",i))
        
        local command = string.format("convert \"%s\" " ..
        	"-resize 1920x1080^ " ..
        	"-gravity center " .. 
        	"-crop 1920x1080+0+0 +repage " .. 
        	"%s", 
        	rendition.destinationPath,
        	rendition.destinationPath)
        myLogger:info(string.format("command: %s", command))
        LrTasks.execute(command)
      else
        LrErrors.throwUserError("Lightroom rendition failed.")
      end
    end
    
    --progressScope:setCaption("Rendering Video")
    -- -b 320k # bit rate
	local appPath = LrPathUtils.child(_PLUGIN.path, "ffmpeg")
    local outputPath = exportParams.LR_export_destinationPathPrefix
	local filePattern = "\%05d.jpg" -- LrPathUtils.child
	local codec = exportParams.codec -- default "libx264"
	local frameRate = exportParams.framerate -- default "30"
	local size = exportParams.size -- default "1920x1080"
	local scale = "scale=-1:1080"
	-- local scaleExpr = "'if(gt(a,4/3),1920,-1)':'if(gt(a,4/3),-1,1080)'"
	-- crop expression crop=w:h:x:y
	-- crop=in_w/2:in_h/2:(in_w-out_w)/2+((in_w-out_w)/2)*sin(t*10):(in_h-out_h)/2 +((in_h-out_h)/2)*sin(t*13)"
	-- crop=in_w/2:in_h/2:y:10+10*sin(n/10)
	-- formula - crop = height - (width / (16.0 / 9.0))
	-- filter: deshake, vidstabtransform, vidstabdetect
	-- container: asf, avi, flv, mkv, mpg, mp4, ogg
	local pixelFormat = "yuv420p"
	local outputFile = exportParams.filename -- LrPathUtils.child
	--local redirect = "1> ffmpeg.log 2>&1"
	local command = string.format("\"%s\" -y -progress /tmp/status.txt -i %s/%s -c:v %s -r %s -vf %s -pix_fmt %s \"%s/%s\"", 
		appPath, outputPath, filePattern, codec, frameRate, scale, pixelFormat, outputPath, outputFile)
    myLogger:info(string.format("render command: %s", command))
    
	myLogger:trace("starting ffmpeg process")
    --result = LrTasks.execute(command)
    local renderProgress = LrProgressScope({
      parent = progressScope,
      parentEndRange = 1,
      caption = LOC("$$$/VideoRenderer/ProgressExport=Rendering ^1 Frames", numPhotos),
      functionContext = functionContext
    })
    
    io.open("/tmp/status.txt", "w"):close() -- touch to ensure file exists
    LrTasks.startAsyncTask(function ()
    	renderProgress:setPortionComplete(0,nil)
		local result = LrTasks.execute(command)
    	myLogger:trace(string.format("ffmpeg finished with exit code: %d", result))
    	renderProgress:setPortionComplete(1,nil)
   		renderProgress:done()
	end, "rendererTask")
    
    --fh,err = io.open("/tmp/status.txt","r")
    --if err then myLogger:error("Could not open file /tmp/status.txt" .. err); return; end
    --while true do
    --	line = fh:read()
    --    if line == nil then break end
    --    myLogger:trace("status.txt: " .. line)
    --    if string.find(line,"frame") then
    --            --myLogger:trace(line)
    --    end
    --    if (renderProgress:isDone()) then break end
    --end
    --fh:close()
    io.delete("/tmp/status.txt")
    
    --progressScope:done()
end

return exportServiceProvider