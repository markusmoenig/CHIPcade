var relearn_search_index = [
  {
    "content": "TODO\n",
    "description": "",
    "tags": null,
    "title": "Layers",
    "uri": "/language/layers/index.html"
  },
  {
    "content": "v0.1.0 (2024-11-XX) First version Started CHIPcade Development Mid 2024 Another journey begins\n",
    "description": "",
    "tags": null,
    "title": "News",
    "uri": "/news/index.html"
  },
  {
    "content": "TODO\n",
    "description": "",
    "tags": null,
    "title": "Sprites",
    "uri": "/language/sprites/index.html"
  },
  {
    "content": "CPU 16bit processor with 8 registers, flags and a stack.\nInstruction Set TAG CodeTag. Set a code tag (for Jump or Call instructions).\n# Text. Set a comment.\nNOP. No operation. Does nothing.\nLD Rd Memory + Offset. Load memory to the destination register.\nLDI Rd Value. Load an immediate value to the destination register.\nLDRESX Rd. Load the x value of the screen resolution to the destination register.\nLDRESY Rd. Load the y value of the screen resolution to the destination register.\nST Memory + Offset Rs. Store the source register at the destination memory address.\nADD Rd Rs. Add the source to the destination register.\nSUB Rd Rs. Subtract the source from the destination register.\nMUL Rd Rs. Multiply the source with the destination register.\nDIV Rd Rs. Divide the destination by the source register.\nMOD Rd Rs. Modulus of the destination by the source register.\nINC Rd. Increase the destination register by 1.\nDEC Rd. Decrease the destination register by 1.\nCALL CodeTag. Saves the current code address on the stack and invokes the subroutine.\nRET. Returns from a subroutine invoked by CALL. Pops the code address from the stack and continues execution after the original CALL statement. If there is no address on the stack, stops execution.\nCMP Rd Rs. Compare two registers.\nJ CodeTag. Unconditional jump.\nJE CodeTag. Jump if the zero flag is set (equality check).\nJNE CodeTag. Jump if the zero flag is not set (inequality check).\nJL CodeTag. Jump if the negative flag is set (less than).\nJG CodeTag. Jump if the zero flag is clear and the negative flag is clear (greater than).\nJC CodeTag. Jump if the carry flag is set (used for unsigned comparisons).\nJO CodeTag. Jump if the overflow flag is set (used for signed overflows).\nRAND Rd Value. Generates a random number of type Value in the range of 0…Value and stores it in the destination register.\nCPU Flags Zero Flag (ZF). Set when the result of an operation is zero. Carry Flag (CF). Set when an arithmetic operation results in an unsigned overflow (carry out of the most significant bit) or underflow (borrow into the most significant bit). Overflow Flag (OF). Set when an arithmetic operation results in signed overflow (when the result exceeds the range of the signed data type). ** Negative Flag (NF)**. Set when the result of an operation is negative (for signed operations). GCP (Graphical Co-Processor) 8 layers with 256 hardware sprites, a palette, image groups and other hardware supported features.\nLayers Layers are drawn starting from index 0 up to 7. By default layers are in the resolution of the screen and invisible.\nLYRRES L Width Height. Set a custom layer resolution in the form of “320 200”. By default layers are in the resolution of the screen. LYRVIS Ld State. Set layer visibility. Default is invisible. Sprites 256 hardware sprites\nSPRLYR Sd Ls. Assign a layer to the sprite. By default a sprite is not bound to a layer and will be drawn on top of all layers.\nSPRSET Sd ImageGroup. Assign an image group to the sprite.\nSPRIMG Sd Rs. Set the index of the image in the current image group. Stops any animation. Default is 0.\nSPRANM Sd From To. Set the animation range for the sprite and start animation. If the current image index is not inside the range set it to the animation start frame.\nSPRFPS Sd Value. Set the fps for the sprite’s animation. Default is 10.\nSPRVIS Sd State. Set sprite visibility (Invisible/Visible). Default is invisible.\nSPRWRP Sd State. Set the wrapping mode for the sprite (Off/On). Wrapped sprites wrap around the layer or screen (i.e. when they go offscreen re-appear on the other side).\nSPRX Sd Rs. Set the x position of the sprite.\nSPRY Sd Rs. Set the y position of the sprite.\nSPRROT Sd Rs. Set the rotation of the sprite.\nSPRPRI Sd Rs. Set the priority of the sprite. Sprite with a lower priority are drawn last. Default is 0.\nSPRACC Sd Rs. Apply an acceleration impulse to the sprite.\nSPRSPD Sd Rs. Set a constant speed to the sprite.\nSPRMXS Sd Rs. Set the maximum speed for the sprite (for acceleration / impulse driven games).\nSPRFRI Sd Rs. Set the friction of the sprite (default is 1.0). A friction lower than 1.0 will reduce speed.\nSPRGRP Sd Value. Set the collision group of the sprite to the given value. The value can be any numerical value.\nSPRCOL Sd Value. Checks if the sprite collides with any sprite in the collision group. If no, sets the ZF to 1, if yes sets the ZF to 0.\n",
    "description": "",
    "tags": null,
    "title": "Reference",
    "uri": "/language/reference/index.html"
  },
  {
    "content": "TODO\n",
    "description": "",
    "tags": null,
    "title": "CHIPcade Assembly",
    "uri": "/language/index.html"
  },
  {
    "content": "TODO\n",
    "description": "",
    "tags": null,
    "title": "Tutorials",
    "uri": "/tutorials/index.html"
  },
  {
    "content": "",
    "description": "",
    "tags": null,
    "title": "Categories",
    "uri": "/categories/index.html"
  },
  {
    "content": "A list of people who have contributed to CHIPcade:\nAcknowledgements ansimuz for providing the free artwork used in some of the example games. ",
    "description": "",
    "tags": null,
    "title": "Credits",
    "uri": "/more/credits/index.html"
  },
  {
    "content": "Forged Thoughts is a modeling and rendering programming language. It is open source under the MIT license and currently in early development. The language utilizes 3D and 2D SDFs and is written in Rust and can be easily installed as a Rust subcommand.\nForged Thoughts strives to create high-quality distance field models for rendering and poligonization. It utilizes multi-threaded CPU based rendering in 64-bit to prevent the limitations of SDFs on the GPU. The focus is on quality, rather than speed.\nFeatures Easy to use programming language with special modeling functionality. Inbuild renderer for Phong, PBR and a full featured BSDF pathtracer. Polygonization of models (OBJ). 64-bit heavily multi-threaded ray-marcher running on the CPU. Access to all SDF modeling primitives, modifiers and tricks (In progress). Goals The overall project goals are:\nCreate signed distance fields for rendering and poligonization. Focus is on quality rather than speed (although all example render in just a few hundred ms on my machine). CPU based rather than GPU based. All computation is done in 64-bit. Provide an easy but powerful syntax to model and render SDFs without any limitations. Animation( TODO) Object hierarchies by including sub-class scripts (TODO) Share objects and materials via an integrated database (TODO) Model and work with 2D SDFs and Text as an overlay to the 3D layer (TODO) Terrain (TODO) Physics (TODO) Examples Wine Glass The modeling of the glass, except the materials, is just 10 lines.\n// Glass let glass = Cone(0.6, 0.7, 0.6); glass.rounding = 0.2; glass.material.rgb = F3(1.0, 1.0, 1.0); glass.material.roughness = 0.0; glass.material.transmission = 1.0; glass.material.ior = 1.50; let interior = glass.copy(); interior.scale = 0.96; // Fluid let fluid = interior.copy(); fluid.scale -= 0.0002; fluid.material.rgb = F3(\"722F37\").to_linear(); fluid.material.transmission = 1.0; fluid.material.roughness = 0.5; fluid.material.ior = 1.3443705; // Red Wine fluid.material.clearcoat_gloss = 1.0; fluid.material.sheen = 1.0; fluid.material.sheen_tint = 1.0; fluid.max.y = 0.0; glass -= interior; // Top: Smooth Cut Off \u0026 Gold Rim let box = Box(); box.material.rgb = F3(\"d4af37\"); box.material.metallic = 1.0; box.material.roughness = 0.2; box.position.y = 1.5; // Smoothly subtract the box from the glass glass -= Smooth(box, 0.01); // Create a groove with the gold material of the box glass += Groove(box, 0.001, 0.07); Helmet The above helmet was created with the following code:\n// Main shape - We make a smooth blend between a sphere and a cone let sphere = Sphere(0.24); let cone = Cone(0.3, 0.25, 0.0); let helmet = smin(sphere, cone, 0.5); // Assign the material helmet.material.rgb = F3(\"9F6F4A\"); helmet.material.metallic = 0.7; helmet.material.roughness = 0.3; // Make it hollow by creating a copy, subtract and move it down a bit // to open the bottom let cut_out = helmet.copy(); cut_out.position.y -= 0.04; cut_out.scale = 0.98; helmet -= cut_out; // Eye holes - We mirror an Ellipsoid on the x-axis and subtract it. let eyes = Ellipsoid(); eyes.size = F3(0.11, 0.03, 0.1); eyes.position = F3(0.06, -0.03, 0.3); eyes.mirror.x = true; helmet -= eyes; // Nose and mouth - We modify a box and subtract it. let cut = Box(F3(0.07, 0.2, 0.1)); cut.position.y -= 0.25; cut.position.z = 0.2; let modifier = RayModifier(\"x\", \"*\", \"sin\", \"y\"); modifier.frequency = 10.0; modifier.amplitude = 0.7; modifier.addend = 1.0; cut.modifier = modifier; helmet -= cut; // Stripe - We add a positive groove in the intersection between // the helmet and a box. let stripe = Box(F3(0.011, 0.17, 0.2)); stripe.position.y = 0.16; stripe.position.z = 0.2; helmet += Groove(stripe, 0.01, 0.02); Current 3D SDF Primitives Sphere Box Cone / CappedCone Ellipsoid Torus Cylinder Current Booleans Addition Addition Smooth Addition Groove Subtraction Subtraction Smooth Subtraction Groove Intersection Intersection Smooth Current Merging Functions smin Current Modifier Twist Mirroring Max Onion License Forged Thoughts is licensed under the MIT.\nUnless explicitly stated otherwise, any contribution intentionally submitted for inclusion in Forged Thoughts, shall be MIT licensed as above, without any additional terms or conditions.\nSponsors None yet\n",
    "description": "",
    "tags": null,
    "title": "Forged Thoughts",
    "uri": "/index.html"
  },
  {
    "content": "",
    "description": "",
    "tags": null,
    "title": "Tags",
    "uri": "/tags/index.html"
  }
]
