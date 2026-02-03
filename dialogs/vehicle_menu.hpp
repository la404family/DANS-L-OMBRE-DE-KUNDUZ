class Refour_Vehicle_Dialog
{
    idd = 8888;
    movingEnable = false;
    enableSimulation = true;
    class controlsBackground
    {
        class MainBackground: RscText
        {
            idc = -1;
            x = 0.15 * safezoneW + safezoneX;
            y = 0.12 * safezoneH + safezoneY;
            w = 0.70 * safezoneW;
            h = 0.55 * safezoneH;
            colorBackground[] = {0,0,0,0.7};
        };
        class Title: RscText
        {
            idc = -1;
            text = "$STR_GARAGE_TITLE";
            x = 0.15 * safezoneW + safezoneX;
            y = 0.12 * safezoneH + safezoneY;
            w = 0.70 * safezoneW;
            h = 0.04 * safezoneH;
            colorBackground[] = {0,0.5,0.8,1};
            style = ST_CENTER;
        };
    };
    class controls
    {
        class UnitList: RscListBox
        {
            idc = 1500;
            x = 0.16 * safezoneW + safezoneX;
            y = 0.17 * safezoneH + safezoneY;
            w = 0.68 * safezoneW;
            h = 0.42 * safezoneH;
        };
        class ButtonRecruit: RscButton
        {
            idc = 5502;
            text = "$STR_GARAGE_TAKE_OUT";
            x = 0.16 * safezoneW + safezoneX;
            y = 0.61 * safezoneH + safezoneY;
            w = 0.20 * safezoneW;
            h = 0.04 * safezoneH;
            action = "['SPAWN'] call MISSION_fnc_spawn_vehicles;";
        };
        class ButtonDelete: RscButton
        {
            idc = 5503;
            text = "$STR_BTN_DELETE";
            x = 0.40 * safezoneW + safezoneX;
            y = 0.61 * safezoneH + safezoneY;
            w = 0.20 * safezoneW;
            h = 0.04 * safezoneH;
            action = "['DELETE'] call MISSION_fnc_spawn_vehicles;";
        };
        class ButtonClose: RscButton
        {
            idc = -1;
            text = "$STR_CLOSE";
            x = 0.64 * safezoneW + safezoneX;
            y = 0.61 * safezoneH + safezoneY;
            w = 0.20 * safezoneW;
            h = 0.04 * safezoneH;
            action = "closeDialog 0;";
        };
    };
};

class Refour_Weather_Time_Dialog
{
    idd = 9999;
    movingEnable = false;
    enableSimulation = true;
    class controlsBackground
    {
        class MainBackground: RscText
        {
            idc = -1;
            x = 0.25 * safezoneW + safezoneX;
            y = 0.25 * safezoneH + safezoneY;
            w = 0.50 * safezoneW;
            h = 0.50 * safezoneH;
            colorBackground[] = {0,0,0,0.7};
        };
        class Title: RscText
        {
            idc = -1;
            text = "$STR_WEATHER_TITLE";
            x = 0.25 * safezoneW + safezoneX;
            y = 0.25 * safezoneH + safezoneY;
            w = 0.50 * safezoneW;
            h = 0.04 * safezoneH;
            colorBackground[] = {0,0.5,0.8,1};
            style = ST_CENTER;
        };
        class LabelTime: RscText
        {
            idc = -1;
            text = "$STR_LABEL_TIME";
            x = 0.27 * safezoneW + safezoneX;
            y = 0.32 * safezoneH + safezoneY;
            w = 0.15 * safezoneW;
            h = 0.04 * safezoneH;
        };
        class LabelClouds: RscText
        {
            idc = -1;
            text = "$STR_LABEL_CLOUDS";
            x = 0.27 * safezoneW + safezoneX;
            y = 0.42 * safezoneH + safezoneY;
            w = 0.15 * safezoneW;
            h = 0.04 * safezoneH;
        };
        class LabelFog: RscText
        {
            idc = -1;
            text = "$STR_LABEL_FOG";
            x = 0.27 * safezoneW + safezoneX;
            y = 0.52 * safezoneH + safezoneY;
            w = 0.15 * safezoneW;
            h = 0.04 * safezoneH;
        };
    };
    class controls
    {
        class ComboTime: RscCombo
        {
            idc = 2100;
            x = 0.45 * safezoneW + safezoneX;
            y = 0.32 * safezoneH + safezoneY;
            w = 0.25 * safezoneW;
            h = 0.04 * safezoneH;
        };
        class ComboClouds: RscCombo
        {
            idc = 2101;
            x = 0.45 * safezoneW + safezoneX;
            y = 0.42 * safezoneH + safezoneY;
            w = 0.25 * safezoneW;
            h = 0.04 * safezoneH;
        };
        class ComboFog: RscCombo
        {
            idc = 2102;
            x = 0.45 * safezoneW + safezoneX;
            y = 0.52 * safezoneH + safezoneY;
            w = 0.25 * safezoneW;
            h = 0.04 * safezoneH;
        };
        class ButtonApply: RscButton
        {
            idc = 2600;
            text = "$STR_BTN_APPLY";
            x = 0.30 * safezoneW + safezoneX;
            y = 0.65 * safezoneH + safezoneY;
            w = 0.15 * safezoneW;
            h = 0.04 * safezoneH;
            action = "['APPLY'] call MISSION_fnc_spawn_weather_and_time;";
        };
        class ButtonClose: RscButton
        {
            idc = -1;
            text = "$STR_CLOSE";
            x = 0.55 * safezoneW + safezoneX;
            y = 0.65 * safezoneH + safezoneY;
            w = 0.15 * safezoneW;
            h = 0.04 * safezoneH;
            action = "closeDialog 0;";
        };
    };
};
