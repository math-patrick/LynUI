local _, ns = ...

-- Lyn's fonts and bar textures, registered with SharedMedia so they show up
-- in every EllesmereUI font/texture dropdown. Registered at file load so they
-- exist before EllesmereUI builds its media lists.
ns.FONTS = {
	['Lyn Roboto Slab'] = 'RobotoSlab-Bold.ttf',
	['Lyn Roboto Slab Regular'] = 'RobotoSlab-Regular.ttf',
	['Lyn Passion One'] = 'PassionOne-Regular.ttf',
	['Lyn Cameltoe'] = 'CAMELTOEkalypse.ttf',
}

ns.STATUSBARS = {
	['Lyn Fer35'] = 'fer35.tga',
	['Lyn Smooth'] = 'lyn1.tga',
	['Lyn Striped'] = 'lyn2.tga',
	['Lyn Gradient'] = 'gradient3.tga',
}

local LSM = LibStub and LibStub('LibSharedMedia-3.0', true)
if not LSM then return end

for name, file in pairs(ns.FONTS) do
	LSM:Register(LSM.MediaType.FONT, name, ns.MEDIA .. [[fonts\]] .. file)
end

for name, file in pairs(ns.STATUSBARS) do
	LSM:Register(LSM.MediaType.STATUSBAR, name, ns.MEDIA .. [[statusbars\]] .. file)
end
