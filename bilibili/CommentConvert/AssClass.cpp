//
//  AssClass.cpp
//  danmaku2ass_native
//
//  Created by TYPCN on 2015/4/8.
//
//

#include "AssClass.hpp"
#include <string.h>
#include <math.h>
#include <iostream>
#include <sstream>

using namespace std;

void Ass::init(const char *filename){
    std::remove(filename);
    out.open(filename);
}

void Ass::SetDuration(int dm,int ds){
    duration_marquee = dm;
    duration_still = ds;
}

void Ass::WriteHead(int width,int height,const char *font,float fontsize,float alpha){
    
    srand((int)time(0));
    
    FontSize = fontsize;
    VideoHeight = height;
    VideoWidth = width;
    
    // Write a♂ss head info
    out << "[Script Info]\nScript Updated By: Danmaku2ASS_native (https://github.com/typcn/danmaku2ass_native)\nScriptType: v4.00+" << endl;
    out << "PlayResX: " << width << endl;
    out << "PlayResY: " << height << endl;
    out << "Aspect Ratio: " << width << ":" << height << endl;
    out << "Collisions: Normal" << endl;
    out << "WrapStyle: 2" << endl;
    out << "ScaledBorderAndShadow: yes" << endl;
    out << "YCbCr Matrix: TV.601" << endl << endl;
    
    char alpha_hex[3];
    sprintf(alpha_hex, "%02X", 255-round_int(alpha*255));
    
    // Write ass styles , maybe disorder , See https://en.wikipedia.org/wiki/SubStation_Alpha
    out << "[V4+ Styles]"<< endl;
    out << "Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding"<< endl;
    
    // Get Style name
    stringstream ss;
    ss << "TYCM_" << rand() % (int)(9999 + 1);
    ss >> style_name;
    
    out << "Style: " <<
    style_name <<  "," << // Style name
    font << ", " << // Font name
    fontsize << ", " << // Font size
    "&H"<< alpha_hex <<"FFFFFF, " << // Primary Color
    "&H"<< alpha_hex <<"FFFFFF, " << // Secondary Color
    "&H"<< alpha_hex <<"000000, " << // Outline Color
    "&H"<< alpha_hex <<"000000, " << // Back Color
    "0, 0, 0, 0, 100, 100, 0.00, 0.00, 1, 1, 0, 7, 0, 0, 0, 0" << endl << endl;
    
    out << "[Events]" << endl;
    out << "Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text" << endl;
}

void Ass::AppendComment(float appear_time,int comment_mode,int font_color,const char *content){
    int duration;

    string str = content;
    
    int ContentFontLen = (int)Utf8StringSize(str)*FontSize;
    
    char effect[30];
    if(comment_mode < 4){
        sprintf(effect,"\\move(%d, [MROW], %d, [MROW])",VideoWidth,-ContentFontLen);
        duration = duration_marquee;
    }else if(comment_mode == 4){
        sprintf(effect,"\\an2\\pos(%d,[BottomROW])",VideoWidth/2);
        duration = duration_still;
    }else if(comment_mode == 5){
        sprintf(effect,"\\an8\\pos(%d,[TopROW])",VideoWidth/2);
        duration = duration_still;
    }else{
        return;
    }
    string effectStr(effect);
    string color = "";
    if(font_color != 16777215){
        if(font_color == 0x000000){
            color = "\\c&H000000&";
        }else if(font_color == 0xffffff){
            color = "\\c&HFFFFFF&";
        }else{
            int R = (font_color >> 16) & 0xff;
            int G = (font_color >> 8) & 0xff;
            int B = font_color & 0xff;
            char hexcolor[7];
            sprintf(hexcolor, "%02X%02X%02X",B,G,R);
            hexcolor[6] = '\0';
            string strcolor(hexcolor);
            color = "\\c&H" + strcolor + "&";
        }
    }

    stringstream ss;
    ss << "Dialogue: 2," << TS2t(appear_time) << "," << TS2t(appear_time + duration) << "," << style_name << ",,0000,0000,0000,,{" << effectStr << color << "}" << content;
    
    pair<int,std::string> contentPair = make_pair(ContentFontLen,ss.str());
    
    comment_map.insert( std::pair<float, std::pair<int,std::string>>(appear_time,contentPair) );
    
}

int Ass::round_int( double r ) {
    return (r > 0.0) ? (r + 0.5) : (r - 0.5);
}

inline string Ass::TS2t(double timestamp){
    
    int ts= (int)timestamp*100.0;
    int hour,minute,second,centsecond;
    hour = ts/360000;
    minute = ts%360000;
    second = minute%6000;
    minute = minute/6000;
    centsecond = second%100;
    second = second/100;
    char buff[20];
    sprintf(buff,"%d:%02d:%02d.%02d", hour,minute,second,centsecond);
    return string(buff);
}

template<typename _Iterator1, typename _Iterator2>
inline size_t IncUtf8StringIterator(_Iterator1& it, const _Iterator2& last) {
    if(it == last) return 0;
    unsigned char c;
    size_t res = 1;
    for(++it; last != it; ++it, ++res) {
        c = *it;
        if(!(c&0x80) || ((c&0xC0) == 0xC0)) break;
    }
    
    return res;
}

inline size_t Ass::Utf8StringSize(const std::string& str)  {
    size_t res = 0;
    std::string::const_iterator it = str.begin();
    for(; it != str.end(); IncUtf8StringIterator(it, str.end()))
        res++;
    
    return res;
}

static inline std::string ReplaceAll(std::string str, const std::string& from, const std::string& to) {
    size_t start_pos = 0;
    while((start_pos = str.find(from, start_pos)) != std::string::npos) {
        str.replace(start_pos, from.length(), to);
        start_pos += to.length(); // Handles case where 'to' is a substring of 'from'
    }
    return str;
}

void Ass::WriteToDisk(bool removeBottom){
    
    int All_Rows = 0;
    int Dropped_Rows = 0;
    
    typedef std::map<float, pair<int,std::string>>::iterator it_type;
    
    float TopTime = 0;
    float BottomTime = 0;
    
    int TopROW = -1;
    int BottomROW = -1;
    
    int line = ceil(VideoHeight/FontSize);
    
    double *rows_dismiss_time = new double[line]; // The time of scroll comment dismiss
    double *rows_visible_time = new double[line]; // The time of last char visible on screen
    
    for(it_type iterator = comment_map.begin(); iterator != comment_map.end(); iterator++) {
        
        All_Rows++;
        
        string r = iterator->second.second;
        
        int playbackTime = iterator->first;
        double TextWidth = iterator->second.first + 2.0; // Add some space between texts
        double act_time = TextWidth / (((double)VideoWidth + TextWidth)/ (double)duration_marquee); // duration of last char visible on screen
        
        if(r.find("[MROW]") != std::string::npos){
            bool Replaced = false;
            for(int i=0;i < line;i++){
                double Time_Arrive_Border = (playbackTime + (double)duration_marquee) - act_time; // The time of first char reach left border of video
                if(Time_Arrive_Border > rows_dismiss_time[i] && playbackTime > rows_visible_time[i]){
                    rows_dismiss_time[i] = playbackTime + (double) duration_marquee;
                    rows_visible_time[i] = playbackTime + act_time;
                    r = ReplaceAll(r,"[MROW]",to_string(i*FontSize));
                    Replaced = true;
                    break;
                }
            }
            if(!Replaced){
                r = "";
                Dropped_Rows++;
            }
        }else if(r.find("[TopROW]") != std::string::npos){
            float timeago =  iterator->first - TopTime;
            if(timeago > duration_still){
                TopROW = 0;
                TopTime = iterator->first;
            }else{
                TopROW++;
            }
            r = ReplaceAll(r,"[TopROW]",to_string(TopROW*FontSize));
        }else if(r.find("[BottomROW]") != std::string::npos){
            if(removeBottom){
                continue;
            }else{
                float timeago =  iterator->first - BottomTime;
                if(timeago > duration_still){
                    BottomROW = 0;
                    BottomTime = iterator->first;
                }else{
                    BottomROW++;
                }
                r = ReplaceAll(r,"[BottomROW]",to_string(VideoHeight-BottomROW*FontSize));
            }
        }else{
            continue;
        }
        
        out << r << endl;
    }
    
    cout << "Comments:" << All_Rows << " Dropped:" << Dropped_Rows << endl;
}
