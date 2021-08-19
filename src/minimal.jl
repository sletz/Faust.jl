# ************************************************************************
# FAUST Architecture File
# Copyright (C) 2021 GRAME, Centre National de Creation Musicale
# ---------------------------------------------------------------------

# This is sample code. This file is provided as an example of minimal
# FAUST architecture file. Redistribution and use in source and binary
# forms, with or without modification, in part or in full are permitted.
# In particular you can create a derived work of this FAUST architecture
# and distribute that work under terms of your choice.

# This sample code is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# ************************************************************************

const FAUSTFLOAT = Float32

# Generated code
<<includeIntrinsic>>
<<includeclass>>

# Retrieve the application name
mutable struct NameMeta <: FMeta
    name::String
end

import Faust.declare!

function declare!(m::NameMeta, key::String, value::String)
    if (key == "name") 
        m.name = value;
    end
end

# Testing
using Plots

samplerate = Int32(44100)
block_size = Int32(512 * 10)

test!() = begin
    # Init DSP
    my_dsp = mydsp{REAL}()
    init!(my_dsp, samplerate)

    m = NameMeta("")
    metadata!(my_dsp, m)
    println("Application name: ", m.name, "\n")

    println("getNumInputs: ", getNumInputs(my_dsp))
    println("getNumOutputs: ", getNumOutputs(my_dsp), "\n")
    
    # Create a MapUI controller
    map_ui = MapUI(my_dsp)
    buildUserInterface!(my_dsp, map_ui)

    # Print all zones
    println("Path/UIZone dictionary: ", getZoneMap(map_ui), "\n")
   
    inputs = zeros(FAUSTFLOAT, block_size, getNumInputs(my_dsp))
    outputs = zeros(FAUSTFLOAT, block_size, getNumOutputs(my_dsp)) 
    compute!(my_dsp, block_size, inputs, outputs)
    
    # display the outputs
    display(plot(outputs, layout = (getNumOutputs(my_dsp), 1)))
    
end

test!()
