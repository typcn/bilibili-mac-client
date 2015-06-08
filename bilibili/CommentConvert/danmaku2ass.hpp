//
//  danmaku2ass.hpp
//  bilibili
//
//  Created by TYPCN on 2015/6/7.
//  Copyright (c) 2015 TYPCN. All rights reserved.
//

#ifndef bilibili_danmaku2ass_h
#define bilibili_danmaku2ass_h

#include <string>
#include <vector>

void danmaku2ass(const char *infile,const char *outfile,int width,int height,const char *font,float fontsize,float alpha,float duration_marquee,float duration_still);

#endif

#ifndef bilibili_danmaku2ass_hpp
#define bilibili_danmaku2ass_hpp

class bilibiliParser{
private:
    std::vector<const char *> blockWords;
    const char *in;
    const char *out;
    int width = 1280;
    int height = 720;
    const char *font = "Heiti";
    float fontsize = 20;
    float alpha = 0.8;
    float duration_marquee = 5;
    float duration_still = 5;
public:
    void SetFile(const char *infile,const char *outfile){ in = infile; out = outfile; };
    void SetRes(int w,int h){ width = w; height = h; };
    void SetFont(const char *name,float size){ font = name; fontsize = size; };
    void SetAlpha(float a){ alpha = a; };
    void SetDuration(float scroll,float still){ duration_marquee = scroll; duration_still = still; };
    void SetBlockWord(const char *word){ blockWords.push_back(word); };
    bool Convert(bool removeBottom);
};

#endif