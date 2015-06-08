//
//  AssClass.h
//  danmaku2ass_native
//
//  Created by TYPCN on 2015/4/8.
//
//

#ifndef __danmaku2ass_native__AssClass__
#define __danmaku2ass_native__AssClass__

#include <stdio.h>
#include <fstream>
#include <map>

class Ass{
private:
    std::ofstream out;
    std::map <float, std::pair<int, std::string>> comment_map;
    int round_int( double r );
    char style_name[10];
    
    inline std::string TS2t(double timestamp);
    
    inline size_t Utf8StringSize(const std::string& str);
    
    int duration_marquee;
    int duration_still;
    
    int VideoWidth;
    int VideoHeight;
    
    int FontSize;
    
public:
    void init(const char *filename);
    void SetDuration(int dm,int ds);
    void WriteHead(int width,int height,const char *font,float fontsize,float alpha);
    void AppendComment(float appear_time,int comment_mode,int font_color,const char *content);
    void WriteToDisk(bool removeBottom);
};

#endif /* defined(__danmaku2ass_native__AssClass__) */
