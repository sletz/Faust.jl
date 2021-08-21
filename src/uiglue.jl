using Base: CFunction, Float32, Float64

mutable struct PathBuilder
    controlsLevel::Array{String}
end

function pushLabel!(builder::PathBuilder, label::String)
    push!(builder.controlsLevel, label)
end

function popLabel!(builder::PathBuilder)
    deleteat!(builder.controlsLevel, lastindex(builder.controlsLevel))
end

function buildPath(builder::PathBuilder, label::String)
    path = join(builder.controlsLevel, "/")
    res = "/$path/$label"
    for c in [' ', '#', '*', ',', '?', '[', ']', '{', '}', '(', ')'] 
        res = replace(res, c => '_')
    end
    res
end

mutable struct GlueFns
    openTabBox::CFunction
    openHorizontalBox::CFunction
    openVerticalBox::CFunction
    closeBox::CFunction
    addButton::CFunction
    addCheckButton::CFunction
    addVerticalSlider::CFunction
    addHorizontalSlider::CFunction
    addNumEntry::CFunction
    addHorizontalBargraph::CFunction
    addVerticalBargraph::CFunction
    # addSoundfile::CFunction
    declare::CFunction
end

struct UIRange{T}
    init::T
    min::T
    max::T
    step::T
end

mutable struct UIGlue{T}
    uiInterface::Ptr{Cvoid}
    openTabBox::Ptr{Cvoid}
    openHorizontalBox::Ptr{Cvoid}
    openVerticalBox::Ptr{Cvoid}
    closeBox::Ptr{Cvoid}
    addButton::Ptr{Cvoid}
    addCheckButton::Ptr{Cvoid}
    addVerticalSlider::Ptr{Cvoid}
    addHorizontalSlider::Ptr{Cvoid}
    addNumEntry::Ptr{Cvoid}
    addHorizontalBargraph::Ptr{Cvoid}
    addVerticalBargraph::Ptr{Cvoid}
    addSoundfile::Ptr{Cvoid}
    declare::Ptr{Cvoid}

    paths::Dict{String,Ptr{T}}
    ranges::Dict{String,UIRange{T}}
    pathBuilder::PathBuilder
    
    gluefns::GlueFns

    function UIGlue{T}() where {T} 
        uglue = new{T}()
        uglue.paths = Dict{String, Ptr{T}}()
        uglue.pathBuilder = PathBuilder([])
        uglue.ranges = Dict{String, UIRange{T}}()
        initGlue!(uglue)
    end
end

function initGlue!(uglue::UIGlue{T}) where {T}

    function _openTabBox(ui, label)::Cvoid
        pushLabel!(uglue.pathBuilder, unsafe_string(label))
        nothing
    end
    openTabBox = @cfunction($_openTabBox, Cvoid, (Ptr{Cvoid}, Cstring))
    
    function _openHorizontalBox(ui, label)::Cvoid
        pushLabel!(uglue.pathBuilder, unsafe_string(label))
        nothing
    end
    openHorizontalBox = @cfunction($_openHorizontalBox, Cvoid, (Ptr{Cvoid}, Cstring))
    
    function _openVerticalBox(ui, label)::Cvoid
        pushLabel!(uglue.pathBuilder, unsafe_string(label))
        nothing
    end
    openVerticalBox = @cfunction($_openVerticalBox, Cvoid, (Ptr{Cvoid}, Cstring))

    function _closeBox(ui)::Cvoid
        popLabel!(uglue.pathBuilder)
        nothing
    end
    closeBox = @cfunction($_closeBox, Cvoid, (Ptr{Cvoid},))

    function _addButton(ui, label, zone)::Cvoid
        path = buildPath(uglue.pathBuilder, unsafe_string(label))
        uglue.paths[path] = zone
        nothing
    end
    addButton = @cfunction(
        $_addButton,
        Cvoid, (Ptr{Cvoid}, Cstring, Ptr{T}))

    function _addCheckButton(ui, label, zone)::Cvoid
        path = buildPath(uglue.pathBuilder, unsafe_string(label))
        uglue.paths[path] = zone
        nothing
    end
    addCheckButton = @cfunction(
        $_addCheckButton,
        Cvoid, (Ptr{Cvoid}, Cstring, Ptr{T}))

    function _addVerticalSlider(ui, label, zone, init, fmin, fmax, step)::Cvoid
        path = buildPath(uglue.pathBuilder, unsafe_string(label))
        uglue.paths[path] = zone
        uglue.ranges[path] = UIRange(init, fmin, fmax, step)
        nothing
    end
    addVerticalSlider = @cfunction(
        $_addVerticalSlider,
        Cvoid, (Ptr{Cvoid}, Cstring, Ptr{T}, T, T, T, T))

    function _addHorizontalSlider(ui, label, zone, init, fmin, fmax, step)::Cvoid
        path = buildPath(uglue.pathBuilder, unsafe_string(label))
        uglue.paths[path] = zone
        uglue.ranges[path] = UIRange(init, fmin, fmax, step)
        nothing
    end
    addHorizontalSlider = @cfunction(
        $_addHorizontalSlider,
        Cvoid, (Ptr{Cvoid}, Cstring, Ptr{T}, T, T, T, T))

    function _addNumEntry(ui, label, zone, init, fmin, fmax, step)::Cvoid
        path = buildPath(uglue.pathBuilder, unsafe_string(label))
        uglue.paths[path] = zone
        uglue.ranges[path] = UIRange(init, fmin, fmax, step)
        nothing
    end
    addNumEntry = @cfunction(
        $_addNumEntry,
        Cvoid, (Ptr{Cvoid}, Cstring, Ptr{T}, T, T, T, T))

    function _addHorizontalBargraph(ui, label, zone, fmin, fmax)::Cvoid
        path = buildPath(uglue.pathBuilder, unsafe_string(label))
        uglue.paths[path] = zone
        nothing
    end
    addHorizontalBargraph = @cfunction(
        $_addHorizontalBargraph,
        Cvoid, (Ptr{Cvoid}, Cstring, Ptr{T}, T, T))

    function _addVerticalBargraph(ui, label, zone, fmin, fmax)::Cvoid
        path = buildPath(uglue.pathBuilder, unsafe_string(label))
        uglue.paths[path] = zone
        nothing
    end
    addVerticalBargraph = @cfunction(
        $_addVerticalBargraph,
        Cvoid, (Ptr{Cvoid}, Cstring, Ptr{T}, T, T))

    function _declare(ui, zone, key, value)::Cvoid
        nothing
    end
    declare = @cfunction(
        $_declare,
        Cvoid, (Ptr{Cvoid}, Ptr{T}, Cstring, Cstring))

# // -- soundfiles   
# typedef void (* addSoundfileFun) (void* ui_interface, const char* label, const char* url, struct Soundfile** sf_zone);
    
    uglue.gluefns = GlueFns(
        openTabBox,
        openHorizontalBox,
        openVerticalBox,
        closeBox,
        addButton,
        addCheckButton,
        addVerticalSlider,
        addHorizontalSlider,
        addNumEntry,
        addHorizontalBargraph,
        addVerticalBargraph,
        declare,
    )
    uglue.openTabBox = uglue.gluefns.openTabBox.ptr
    uglue.openHorizontalBox = uglue.gluefns.openHorizontalBox.ptr
    uglue.openVerticalBox = uglue.gluefns.openVerticalBox.ptr
    uglue.closeBox = uglue.gluefns.closeBox.ptr
    uglue.addButton = uglue.gluefns.addButton.ptr
    uglue.addCheckButton = uglue.gluefns.addCheckButton.ptr
    uglue.addVerticalSlider = uglue.gluefns.addVerticalSlider.ptr
    uglue.addHorizontalSlider = uglue.gluefns.addHorizontalSlider.ptr
    uglue.addNumEntry = uglue.gluefns.addNumEntry.ptr
    uglue.addHorizontalBargraph = uglue.gluefns.addHorizontalBargraph.ptr
    uglue.addVerticalBargraph = uglue.gluefns.addVerticalBargraph.ptr
    uglue.declare = uglue.gluefns.declare.ptr

    uglue
end