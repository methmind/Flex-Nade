local NadesData = {}
local screenCenterX, screenCenterY = draw.GetScreenSize();
screenCenterX = screenCenterX * 0.5;
screenCenterY = screenCenterY * 0.5;

local ref = gui.Tab(gui.Reference("Ragebot"), "flex_nade", "Flex Nade");
local guiHelperSettingsBlock = gui.Groupbox(ref, "Helper Settings", 16, 16, 250, 250);
local guiHelperEnable = gui.Checkbox(guiHelperSettingsBlock , "nade_enable", "Helper Enable", 1);
local guiHelperDrawDistance = gui.Slider(guiHelperSettingsBlock, "nade_draw_dist", "Draw Distance", 350, 0, 1000);
local guiHelperPDrawDistance = gui.Slider(guiHelperSettingsBlock, "nade_pdraw_dist", "Draw Pointer Distance", 20, 0, 100);
local guiHelperActivationDistance = gui.Slider(guiHelperSettingsBlock, "nade_activation_dist", "Helper Activation Distance", 60, 0, 300);
local guiHelperFov = gui.Slider(guiHelperSettingsBlock, "nade_fov", "Helper FOV", 10, 0, 250);
local guiHelperTextColor = gui.ColorPicker(guiHelperSettingsBlock, "nade_text_color", "Helper Text Color", 171, 153, 242, 255);
local guiHelperCircleColor = gui.ColorPicker(guiHelperSettingsBlock, "nade_circle_color", "Helper Circle Color", 171, 153, 242, 255);
local guiHelperLineColor = gui.ColorPicker(guiHelperSettingsBlock, "nade_line_color", "Helper Line Color", 171, 153, 242, 255);
local guiHelperBackColor = gui.ColorPicker(guiHelperSettingsBlock, "nade_back_color", "Helper Background Color", 0, 0, 0, 120);
local guiHelperMiscBlock = gui.Groupbox(ref, "Helper Misc", 16, 446, 250, 250);
local guiHelperFixGrenadePred = gui.Checkbox(guiHelperMiscBlock, "nade_fixpredict", "Fix Grenade Prediction", 0);

function string:split( inSplitPattern, outResults )
   if not outResults then
      outResults = { }
   end
   local theStart = 1
   local theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
   while theSplitStart do
      table.insert( outResults, string.sub( self, theStart, theSplitStart-1 ) )
      theStart = theSplitEnd + 1
      theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
   end
   table.insert( outResults, string.sub( self, theStart ) )
   return outResults
end

local function addNewNade(positionX, positionY, positionZ, nadeType, nadeTitle, pointerX, pointerY, pointerDistance, moveX, moveY, moveZ, moveType, throwPercent)
	local bFind = false;
	
	for i = 1, #NadesData do
		local nadeInfo = NadesData[i];
		
		if math.floor(nadeInfo[1]) == math.floor(positionX) and math.floor(nadeInfo[2]) == math.floor(positionY) and math.floor(nadeInfo[3]) == math.floor(positionZ) then
			if nadeInfo[4] ~= nadeType then
				nadeInfo[4] = nadeInfo[4] + nadeType;
			end
			nadeInfo[5] = string.format("%s:%s", nadeInfo[5], nadeTitle);
			table.insert(nadeInfo[6], { pointerX, pointerY, pointerDistance, nadeTitle, { moveX, moveY, moveZ, moveType, throwPercent } } );
			bFind = true;
		end
	end
	
	if not bFind then 
		table.insert(NadesData, { positionX, positionY, positionZ, nadeType, nadeTitle, { { pointerX, pointerY, pointerDistance, nadeTitle, { moveX, moveY, moveZ, moveType, throwPercent } } } } );
	end
end

local function getDistanceToTarget(my_x, my_y, my_z, t_x, t_y, t_z)
    local dx = my_x - t_x;
    local dy = my_y - t_y;
    local dz = my_z - t_z;
    return math.sqrt(dx*dx + dy*dy + dz*dz);
end

local function drawCircle(pos, radius)
	local center = {client.WorldToScreen(Vector3(pos.x, pos.y, pos.z)) }
	for degrees = 1, 20, 1 do
        
        local cur_point = nil;
        local old_point = nil;

        if pos.z == nil then
            cur_point = {pos.x + math.sin(math.rad(degrees * 18)) * radius, pos.y + math.cos(math.rad(degrees * 18)) * radius};    
            old_point = {pos.x + math.sin(math.rad(degrees * 18 - 18)) * radius, pos.y + math.cos(math.rad(degrees * 18 - 18)) * radius};
        else
            cur_point = {client.WorldToScreen(Vector3(pos.x + math.sin(math.rad(degrees * 18)) * radius, pos.y + math.cos(math.rad(degrees * 18)) * radius, pos.z))};
            old_point = {client.WorldToScreen(Vector3(pos.x + math.sin(math.rad(degrees * 18 - 18)) * radius, pos.y + math.cos(math.rad(degrees * 18 - 18)) * radius, pos.z))};
        end
                    
        if cur_point[1] ~= nil and cur_point[2] ~= nil and old_point[1] ~= nil and old_point[2] ~= nil and center[1] ~= nil and center [2] ~= nil then        
            draw.Line(cur_point[1], cur_point[2], old_point[1], old_point[2]);        
        end
       
    end
end

local function getParsedTitle(strTitle)
	local strArray = {};
	local strTemp = "";
	
	for i = 1, #strTitle do
		local c = strTitle:sub(i,i);
		if c == ":" then
			table.insert(strArray, strTemp);
			strTemp = "";
		else
			strTemp = strTemp .. c;
		end
	end
	
	if string.len(strTemp) > 0 then
		table.insert(strArray, strTemp);
	end

	return strArray;
end

local function getTitleSize(strArray)
	local x = 0;
	local y = 0;
	for i = 1, #strArray do
		local tX, tY = draw.GetTextSize(strArray[i]);
		if x == 0 then
			x = tX;
		elseif x < tX then
			x = tX;
		end
		y = y + tY;
	end
	
	return { x, y };
end

local function getThrowPosition(pos_x, pos_y, pos_z, ax, ay, distance, z_offset)
    return pos_x - distance * math.cos(math.rad(ay + 180)), pos_y - distance * math.sin(math.rad(ay + 180)), pos_z - distance * math.tan(math.rad(ax)) + z_offset;
end

local function checkGroundFov(pos_x, pos_y, pos_z, helper_x, helper_y, helper_z)
	local iFov = guiHelperPDrawDistance:GetValue();
	if (pos_x > helper_x - iFov and pos_x < helper_x + iFov) and (pos_y > helper_y - iFov and pos_y < helper_y + iFov)  and (pos_z > helper_z - iFov and pos_z < helper_z + 65) then
		return true;
	end
	
	return false;
end

local function getDistanceToTarget2(x1, y1, x2, y2)
	return math.sqrt(math.pow((x2-x1),2) + math.pow((y2-y1),2));
end

local function DrawNadeInfo()
	if not guiHelperEnable:GetValue() then return; end
	
	local localPlayer = entities.GetLocalPlayer();

	if not localPlayer then 
		return; 
	end
	
	local localPosition = localPlayer:GetAbsOrigin();
	local localWeapon = localPlayer:GetWeaponID();
	local nadeClosestX, nadeClosestY = nil;
	local pointerClosestDist = 0;

	if localWeapon ~= 44 and localWeapon ~= 46 and localWeapon ~= 48 then
		return;
	end
	
	for i = 1, #NadesData do
		local nadeInfo = NadesData[i];
		
		local nadePosX, nadePosY = client.WorldToScreen( Vector3(nadeInfo[1], nadeInfo[2], nadeInfo[3]) );
		local nadeType = nadeInfo[4];

		if getDistanceToTarget(localPosition.x, localPosition.y, localPosition.z, nadeInfo[1], nadeInfo[2], nadeInfo[3]) > guiHelperDrawDistance:GetValue() then
			goto continue;
		end
		
		if nadeType == 1 then
			if localWeapon ~= 44 then 
				goto continue;
			end
		elseif nadeType == 3 then
			if localWeapon ~= 44 and localWeapon ~= 46 and localWeapon ~= 48 then 
				goto continue;
			end
		else
			if localWeapon ~= 46 and localWeapon ~= 48 then 
				goto continue;
			end
		end
		
		if nadePosX ~= nil and nadePosY ~= nil then
			local nadeTitles = getParsedTitle(nadeInfo[5]);
			local nadeTextTitleSize = getTitleSize(nadeTitles);
			
			local nadeTextPosX = nadePosX - nadeTextTitleSize[1] / 2;
			
			draw.Color(guiHelperCircleColor:GetValue());
			drawCircle(Vector3(nadeInfo[1], nadeInfo[2], nadeInfo[3]), 8);
			
			draw.Color(guiHelperBackColor:GetValue());
			draw.FilledRect(nadeTextPosX - 4, nadePosY - 22 - nadeTextTitleSize[2], nadeTextPosX + nadeTextTitleSize[1] + 4, nadePosY - 10);
			draw.Triangle(nadePosX, nadePosY, nadePosX - 8, nadePosY - 10, nadePosX + 8, nadePosY - 10);
			
			draw.Color(guiHelperTextColor:GetValue());
			
			local added = 0;
			for i = 1, #nadeTitles do
				if nadeTitles[2] ~= nil then
					draw.Text(nadePosX - draw.GetTextSize(nadeTitles[i]) / 2, nadePosY - 19 - nadeTextTitleSize[2] + added, nadeTitles[i]);
					added = added + 12;
				else
					draw.Text(nadePosX  - draw.GetTextSize(nadeTitles[i]) / 2, nadePosY - 17 - nadeTextTitleSize[2] + added, nadeTitles[i]);
				end
			end
		end

		for y = 1, #NadesData[i][6] do
			local pointerInfo = NadesData[i][6][y];
			
			local nadeCurPosX, nadeCurPosY, nadeCurPosZ = getThrowPosition(nadeInfo[1], nadeInfo[2], nadeInfo[3], pointerInfo[1], pointerInfo[2], pointerInfo[3], 64);
			local nadeCurX, nadeCurY = client.WorldToScreen( Vector3(nadeCurPosX, nadeCurPosY, nadeCurPosZ) );
		
			if nadeCurX ~= nil and nadeCurY ~= nil and checkGroundFov(localPosition.x, localPosition.y, localPosition.z, nadeInfo[1], nadeInfo[2], nadeInfo[3]) then 
				draw.Color(guiHelperBackColor:GetValue())
				draw.FilledRect(nadeCurX - 10, nadeCurY - 9, nadeCurX + 6 + draw.GetTextSize("  | "..pointerInfo[4]), nadeCurY + 9);
				
				draw.Color(guiHelperTextColor:GetValue());
				draw.FilledCircle(nadeCurX, nadeCurY, 2.8);
				draw.Text(nadeCurX, nadeCurY - 6, "  | "..pointerInfo[4]);
				
				local locaViewAngles = engine:GetViewAngles();
				local pointerDist = getDistanceToTarget2(locaViewAngles.pitch, locaViewAngles.yaw, pointerInfo[1], pointerInfo[2]);
				
				if pointerDist <= guiHelperFov:GetValue() then 
					if not nadeClosestX and not nadeClosestY then
						nadeClosestX = nadeCurX;
						nadeClosestY = nadeCurY;
						pointerClosestDist = pointerDist;
					elseif pointerClosestDist > pointerDist then
						nadeClosestX = nadeCurX;
						nadeClosestY = nadeCurY;
						pointerClosestDist = pointerDist;
					end
				end
			end
		end
		::continue::
	end
	
	if nadeClosestX and nadeClosestY then 
		draw.Color(guiHelperLineColor:GetValue());
		draw.Line(screenCenterX, screenCenterY, nadeClosestX, nadeClosestY);
	end
end

local function move_to_pos(pos, cmd)
	local LocalPlayer = entities.GetLocalPlayer()
	local angle_to_target = (pos - entities.GetLocalPlayer():GetAbsOrigin()):Angles()
	local my_pos = LocalPlayer:GetAbsOrigin()
	 
	local speed = 255
	local dist = vector.Distance({my_pos.x, my_pos.y, my_pos.z}, {pos.x, pos.y, pos.z})
	 
	if dist < 25 then
		speed = 27
	end
	 
	cmd.forwardmove = math.cos(math.rad((engine:GetViewAngles() - angle_to_target).y)) * speed
	cmd.sidemove = math.sin(math.rad((engine:GetViewAngles() - angle_to_target).y)) * speed
end

local iterKostil = 0;
local startMoving = false;
local nadeClosestIndex = 0;
local pointerClosestIndex = 0;
local pointerAngleX = 0;
local pointerAngleY = 0;
local moveDistPointer = 0;
local nadeThrowed = false;

local function MovmentNadeHelper(cmd)
	if not guiHelperEnable:GetValue() then return; end

	local localPlayer = entities.GetLocalPlayer();
	
	if not localPlayer or not input.IsButtonDown(1) then 
		gui.SetValue("misc.strafe.enable", 1);
		gui.SetValue("misc.fastduck", 1);
		startMoving = false;
		iterKostil = 0;
		return; 
	end
	
	local localPosition = localPlayer:GetAbsOrigin();
	local localWeapon = localPlayer:GetWeaponID();

	if localWeapon ~= 44 and localWeapon ~= 46 and localWeapon ~= 48 then
		startMoving = false;
		iterKostil = 0;
	end
	
	if gui.GetValue("misc.fastduck") then
		gui.SetValue("misc.fastduck", 0);
	end
	
	if cmd:GetButtons() ~= 1 then
		startMoving = false;
		iterKostil = 0;
	end
	
	if not startMoving then
		local nadeClosestDist = 0;
		--
		local pointerClosestDist = 0;
		--
		nadeClosestIndex = 0;
		pointerClosestIndex = 0;
		moveDistPointer = 0;
		nadeThrowed = false;
		
		for i = 1, #NadesData do
			local nadeInfo = NadesData[i];
			local nadeDist = getDistanceToTarget(localPosition.x, localPosition.y, localPosition.z, nadeInfo[1], nadeInfo[2], nadeInfo[3]);

			if nadeDist <= guiHelperActivationDistance:GetValue() then
				if nadeClosestDist == 0 then
					nadeClosestDist = nadeDist;
					nadeClosestIndex = i;
				elseif nadeClosestDist > nadeDist then
					nadeClosestDist = nadeDist;
					nadeClosestIndex = i;
				end
			end
		end
		
		if nadeClosestDist == 0 then
			return;
		end
		
		if NadesData[nadeClosestIndex][4] == 1 then
			if localWeapon ~= 44 then 
				return;
			end
		elseif NadesData[nadeClosestIndex][4] == 3 then
			if localWeapon ~= 44 and localWeapon ~= 46 and localWeapon ~= 48 then 
				return;
			end	
		else
			if localWeapon ~= 46 and localWeapon ~= 48 then 
				return;
			end
		end
		
		local localPlayerFlags = localPlayer:GetPropInt("m_fFlags");
		if nadeClosestDist > 0.15 and localPlayerFlags ~= 256 then
			move_to_pos(Vector3(NadesData[nadeClosestIndex][1], NadesData[nadeClosestIndex][2], NadesData[nadeClosestIndex][3]), cmd);
			return;
		end
		
		local localPlayerVelocity = math.sqrt(localPlayer:GetPropFloat( "localdata", "m_vecVelocity[0]" ) + localPlayer:GetPropFloat( "localdata", "m_vecVelocity[1]" ));	
		local aaType = gui.GetValue("rbot.antiaim.advanced.antialign");
		if aaType == 2 then
			if localPlayerVelocity ~= 0.0 then
				return;
			end
		else
			if localPlayerVelocity > 1.01 then
				return;
			end
		end
		
		if cmd:GetButtons() == 1 then
			iterKostil = iterKostil + 0.5;
		else
			startMoving = false;
			iterKostil = 0;
		end
		
		if iterKostil < 1 then
			return;
		end	
		
		gui.SetValue("misc.strafe.enable", 0);
		
		for y = 1, #NadesData[nadeClosestIndex][6] do
			local pointerInfo = NadesData[nadeClosestIndex][6][y];
			
			local locaViewAngles = engine:GetViewAngles();
			local pointerDist = getDistanceToTarget2(locaViewAngles.pitch, locaViewAngles.yaw, pointerInfo[1], pointerInfo[2]);

			if pointerDist <= guiHelperFov:GetValue() then
				if pointerClosestDist == 0 then
					pointerClosestDist = pointerDist;
					pointerClosestIndex = y;
				elseif pointerClosestDist > pointerDist then
					pointerClosestDist = pointerDist;
					pointerClosestIndex = y;
				end
			end
		end
		
		if pointerClosestIndex == 0 then
			return;
		end
		
		pointerAngleX = NadesData[nadeClosestIndex][6][pointerClosestIndex][1];
		pointerAngleY = NadesData[nadeClosestIndex][6][pointerClosestIndex][2];
	end
	
	local movePointer = NadesData[nadeClosestIndex][6][pointerClosestIndex][5];
	
	if moveDistPointer == 0 then
		moveDistPointer = getDistanceToTarget(localPosition.x, localPosition.y, localPosition.z, movePointer[1], movePointer[2], movePointer[3]);
	end
	
	local justthrow = false;
	if movePointer[4] ~= 0 and movePointer[4] ~= 1 then
		startMoving = true;
		local moveDist = getDistanceToTarget(localPosition.x, localPosition.y, localPosition.z, movePointer[1], movePointer[2], movePointer[3]);

		if moveDist > 0.5 then
			move_to_pos(Vector3(movePointer[1], movePointer[2], movePointer[3]), cmd);
		else
			startMoving = false;
		end
		
		if 100 / (moveDistPointer / moveDist) <= movePointer[5] then
			justthrow = true;
			goto puffpuff;
		end
		
		if nadeThrowed then
			startMoving = false;
			return;
		end
	end
	
	::puffpuff::
	if not startMoving or justthrow then
		engine.SetViewAngles(EulerAngles(pointerAngleX, pointerAngleY, 0));
		if movePointer[4] == 0 then
			cmd:SetButtons(0);
		elseif movePointer[4] == 1 then
			if iterKostil < 15 then
				return;
			end
			cmd:SetButtons(2);
		elseif movePointer[4] == 2 then
			cmd:SetButtons(0);
		elseif movePointer[4] == 3 then
			cmd:SetButtons(2);
			startMoving = false;
		end
		nadeThrowed = true;
	end

	iterKostil = 0;
end

local function HelperMisc()
	if guiHelperFixGrenadePred:GetValue() then
		if input.IsButtonDown(1) or input.IsButtonDown(2) then
			gui.SetValue("esp.world.nadetracer.local", 1);
		else
			gui.SetValue("esp.world.nadetracer.local", 0);
		end
	end
end

--

local function ReadFile(str_Path)
	local hFile = file.Open(str_Path, "r");
	local rawData = hFile:Read();
	local parsedData = {};
	local i = 1;
	
	for str in string.gmatch(rawData, "([^\n]+)") do
        parsedData[i] = str
        i = i + 1
    end

	return parsedData;
end

local currentMap = "";
local function DataLoader()
	if currentMap ~= engine.GetMapName() then
		currentMap = engine.GetMapName();
		for k, v in pairs(NadesData) do NadesData[k] = nil end
		
		local rawData = ReadFile("nade.txt");
		for i = 1, #rawData do
			local nadeInfo = rawData[i]:split(";");
			nadeInfo[14] = nadeInfo[14]:gsub("^%s*(.-)%s*$", "%1");

			if nadeInfo[14] == currentMap then
				addNewNade(tonumber(nadeInfo[1]), tonumber(nadeInfo[2]), tonumber(nadeInfo[3]), tonumber(nadeInfo[4]), 
				nadeInfo[5], tonumber(nadeInfo[6]), tonumber(nadeInfo[7]), tonumber(nadeInfo[8]), tonumber(nadeInfo[9]), 
				tonumber(nadeInfo[10]), tonumber(nadeInfo[11]), tonumber(nadeInfo[12]), tonumber(nadeInfo[13]));
			end
		end
	end
end

callbacks.Register("Draw", DataLoader);
--
callbacks.Register("Draw", DrawNadeInfo);
callbacks.Register("Draw", HelperMisc);
callbacks.Register("CreateMove", MovmentNadeHelper);