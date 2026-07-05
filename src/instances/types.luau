local action = require("./action")

export type Instances = {
	AudioChannelSplitter: AudioChannelSplitter,
	AudioPitchShifter: AudioPitchShifter,
	AudioDeviceOutput: AudioDeviceOutput,
	AudioChannelMixer: AudioChannelMixer,
	AudioTextToSpeech: AudioTextToSpeech,
	AudioDeviceInput: AudioDeviceInput,
	AudioDistortion: AudioDistortion,
	AudioCompressor: AudioCompressor,
	AudioEqualizer: AudioEqualizer,
	AudioAnalyzer: AudioAnalyzer,
	AudioListener: AudioListener,
	AudioRecorder: AudioRecorder,
	AudioLimiter: AudioLimiter,
	AudioFlanger: AudioFlanger,
	AudioEmitter: AudioEmitter,
	AudioPlayer: AudioPlayer,
	AudioReverb: AudioReverb,
	AudioFilter: AudioFilter,
	ArcHandles: ArcHandles,
	AudioFader: AudioFader,
	AudioEcho: AudioEcho,
	AdGui: AdGui,
	BoxHandleAdornment: BoxHandleAdornment,
	BillboardGui: BillboardGui,
	BlurEffect: BlurEffect,
	CylinderHandleAdornment: CylinderHandleAdornment,
	ConeHandleAdornment: ConeHandleAdornment,
	CanvasGroup: CanvasGroup,
	Camera: Camera,
	DialogChoice: DialogChoice,
	DragDetector: DragDetector,
	Dialog: Dialog,
	Folder: Folder,
	Frame: Frame,
	Highlight: Highlight,
	Handles: Handles,
	ImageHandLeAdornment: ImageHandleAdornment,
	ImageButton: ImageButton,
	ImageLabel: ImageLabel,
	LineHandleAdornment: LineHandleAdornment,
	ProximityPrompt: ProximityPrompt,
	Part: Part,
	SphereHandLeAdornment: SphereHandleAdornment,
	SelectionSphere: SelectionSphere,
	ScrollingFrame: ScrollingFrame,
	SelectionBox: SelectionBox,
	StyleDerive: StyleDerive,
	SurfaceGui: SurfaceGui,
	StyleSheet: StyleSheet,
	SoundGroup: SoundGroup,
	StyleLink: StyleLink,
	ScreenGui: ScreenGui,
	StyleBase: StyleBase,
	StyleRule: StyleRule,
	Sound: Sound,
	TextButton: TextButton,
	TextLabel: TextLabel,
	TextBox: TextBox,
	UIAspectRatioConstraint: UIAspectRatioConstraint,
	UITextSizeConstraint: UITextSizeConstraint,
	UISizeConstraint: UISizeConstraint,
	UIDragDetector: UIDragDetector,
	UITableLayout: UITableLayout,
	UIPageLayout: UIPageLayout,
	UIGridLayout: UIGridLayout,
	UIListLayout: UIListLayout,
	UIGradient: UIGradient,
	UIFlexItem: UIFlexItem,
	UIPadding: UIPadding,
	UIStroke: UIStroke,
	UICorner: UICorner,
	UIScale: UIScale,
	ViewportFrame: ViewportFrame,
	VideoFrame: VideoFrame,
	WireframeHandleAdornment: WireframeHandleAdornment,
	WorldModel: WorldModel,
	Wire: Wire,
	UIShadow: UIShadow
}
export type function Read(t: type): type
    if t:is("union") then
        for _, component in t:components() do
            if not component:is("function") then
				error(component.tag)
                return component
            end
        end
    end
    
    return if t:is("function") then (t:returns().head :: { type })[1] else t
end

type UnknownConnectCallback = (...any) -> ()

type Signal = RBXScriptSignal

type function getConnect(v: type): type?
	local connect = v:readproperty(types.singleton("Connect"))

	if connect and connect:is("function") then
		local head = connect:parameters().head

		if not head then
			return nil
		end
		local callback = head[2]

		if callback and callback:is("function") then
			return callback
		end
	end

	return nil
end

type function isSignal(v: type): type?
	if v == Signal and v.tag == "class" then
		return UnknownConnectCallback
	-- luau lsp types RBXScriptSignals as tables
	elseif v.tag == "table" then
		local connect = getConnect(v)

		if connect then
			return connect
		end

		-- i cba to test if this is needed or not
		local metatable = v:metatable()

		if metatable then
			connect = getConnect(metatable)

			if connect then
				return connect
			end
		end
	end

	return nil
end

type instance = Instance

type Action = action.Identity

export type function GetInstance(className: type): type
	
	if className.tag == "extern" then
		return className
	end

	return Instances:readproperty(className)
end


-- temp arg for action, because for some reason its not added as a global automatically
export type function PropertiesFor(class: type): type
	local object
	if class:is("singleton") then
		object = Instances:readproperty(class)
	else
		object = class
	end
	local headTable = {}
	local argsTable = { head = headTable }
	local properties = types.newtable()
	local current = object
	local emptyTable = {}

	local readOnlyProperties = table.freeze({
		types.singleton("RobloxLocked"),
		types.singleton("ClassName"),
		types.singleton("UniqueId"),
	})

	while current do
		
		for property, value in current:properties() do
			if table.find(readOnlyProperties, property) then
				continue
			end

			local valueRead = value.read :: type
			local callback = isSignal(valueRead)

			if callback then
				properties:setproperty(property :: any, types.optional(callback))
			elseif valueRead.tag == "function" or valueRead.tag == "intersection" then
				continue
			elseif value.write then
				headTable[1] = types.optional(valueRead)

				properties:setproperty(
					property :: any,
					types.optional(
						types.unionof(
							types.newfunction(emptyTable :: any, argsTable :: any),
							value.write :: any
						)
					)
				)
			end
		end

		current = current:readparent()
	end

	local nestedTableOrFunctionOrChild = types.newtable()
	local functionReturnsChild = types.newfunction()
	local union =
		types.unionof(nestedTableOrFunctionOrChild, functionReturnsChild, instance, Action)

	nestedTableOrFunctionOrChild:setindexer(types.number, union)
	functionReturnsChild:setreturns({ union })

	properties:setindexer(types.number, types.optional(union))

	return properties
end


return {}