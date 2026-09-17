class liberation_taxi {
    idd = 5204;
    movingEnable = false;
    controlsBackground[] = {};

    controls[] = {"OuterBG", "RecycleBG", "OuterBG_F", "InnerBG", "InnerBG_F", "Header", "LabelFob", "FobList", "LightButton", "ArmedButton", "TaxiMap", "ConfirmButton", "CancelButton"};

    objects[] = {};

    class RecycleBG: BgPicture {
        x = (0.2 * safezoneW + safezoneX) - ( 2 * BORDERSIZE);
        y = (0.15 * safezoneH + safezoneY) - (3 * BORDERSIZE);
        w = (0.6 * safezoneW) + (4 * BORDERSIZE);
        h = (0.7 * safezoneH) + (6 * BORDERSIZE);
    };
    class TaxiMap: kndr_MapControl {
        idc = 251;
        x = (0.37 * safezoneW + safezoneX);
        y = (0.2 * safezoneH + safezoneY);
        w = (0.43 * safezoneW);
        h = (0.6 * safezoneH) - ( 1.5 * BORDERSIZE);
    };
    class OuterBG: StdBG {
        colorBackground[] = COLOR_BROWN;
        x = (0.2 * safezoneW + safezoneX) - ( 2 * BORDERSIZE);
        y = (0.15 * safezoneH + safezoneY) - (3 * BORDERSIZE);
        w = (0.6 * safezoneW) + (4 * BORDERSIZE);
        h = (0.7 * safezoneH) + (6 * BORDERSIZE);
    };
    class OuterBG_F: OuterBG {
        style = ST_FRAME;
    };
    class InnerBG: OuterBG {
        colorBackground[] = COLOR_GREEN;
        x = (0.2 * safezoneW + safezoneX)  - ( BORDERSIZE);
        y = 0.2 * safezoneH + safezoneY - (1.5 * BORDERSIZE);
        w = (0.6 * safezoneW) +  (2 * BORDERSIZE);
        h = 0.65 * safezoneH  + (3 * BORDERSIZE);
    };
    class InnerBG_F: InnerBG {
        style = ST_FRAME;
    };
    class Header: StdHeader {
        x = 0.2 * safezoneW + safezoneX - (BORDERSIZE);
        y = 0.14 * safezoneH + safezoneY;
        w = 0.6 * safezoneW + ( 2 * BORDERSIZE);
        h = 0.05 * safezoneH - (BORDERSIZE);
        text = $STR_TAXI_TITLE;
    };
    class LabelFob: StdText {
        x = (0.2 * safezoneW + safezoneX);
        w = (0.15 * safezoneW);
        h = (0.03 * safezoneH);
        y = 0.22 * safezoneH + safezoneY;
        sizeEx = 0.018 * safezoneH;
        text = $STR_TAXI_FOB_LABEL;
    };
    class FobList: StdListBox {
        idc = 201;
        x = 0.2 * safezoneW + safezoneX;
        w = 0.15 * safezoneW;
        y = 0.25 * safezoneH + safezoneY;
        h = (0.35 * safezoneH) - (1.5 * BORDERSIZE);
        shadow = 2;
        onLBSelChanged="";
    };
    class LightButton: StdButton {
        idc = 210;
        x = (0.2 * safezoneW + safezoneX);
        y = (0.63 * safezoneH + safezoneY);
        w = (0.07 * safezoneW) - (0.5 * BORDERSIZE);
        h = (0.05 * safezoneH);
        sizeEx = 0.02 * safezoneH;
        text = $STR_TAXI_CLASS_LIGHT;
        action = "KPLIB_taxi_class_choice = 'light';";
    };
    class ArmedButton: StdButton {
        idc = 211;
        x = (0.28 * safezoneW + safezoneX) + (0.5 * BORDERSIZE);
        y = (0.63 * safezoneH + safezoneY);
        w = (0.07 * safezoneW) - (0.5 * BORDERSIZE);
        h = (0.05 * safezoneH);
        sizeEx = 0.02 * safezoneH;
        text = $STR_TAXI_CLASS_ARMED;
        action = "KPLIB_taxi_class_choice = 'armed';";
    };
    class ConfirmButton: StdButton {
        idc = 202;
        x = (0.39 * safezoneW + safezoneX);
        y = (0.8 * safezoneH + safezoneY);
        w = (0.1 * safezoneW);
        h = (0.05 * safezoneH);
        sizeEx = 0.025 * safezoneH;
        text = $STR_TAXI_CALL_BUTTON;
        action = "taxi_call_confirmed = 1;";
    };
    class CancelButton: StdButton {
        idc = 213;
        x = (0.51 * safezoneW + safezoneX);
        y = (0.8 * safezoneH + safezoneY);
        w = (0.1 * safezoneW);
        h = (0.05 * safezoneH);
        sizeEx = 0.025 * safezoneH;
        text = $STR_RECYCLING_CANCEL;
        action = "closeDialog 0;";
    };
};
