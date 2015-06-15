#include <stdio.h>
#include <string.h>
#include <time.h>
#include <map>
#include <iostream>
#include <fstream>

#include "rapidxml/rapidxml.hpp"
#include "rapidxml/rapidxml_utils.hpp"
#include "AssClass.hpp"
#include "danmaku2ass.h"
#include "danmaku2ass.hpp"

using namespace std;
using namespace rapidxml;

/*
 Get comment type
 
 headline: the first line of comment file
 
 Return:
 1 - Acfun
 2 - Bilibili
 3 - Niconico
 */

int GetCommentType(string headline){
    if(headline.find("\"commentList\":[") != std::string::npos){
        return 1;
    }else if(headline.find("xml version=\"1.0\" encoding=\"UTF-8\"?><i") != std::string::npos or
             headline.find("xml version=\"1.0\" encoding=\"utf-8\"?><i") != std::string::npos or
             headline.find("xml version=\"1.0\" encoding=\"Utf-8\"?>\n") != std::string::npos){
        return 2;
    }else if(headline.find("xml version=\"1.0\" encoding=\"UTF-8\"?><p") != std::string::npos or
             headline.find("!-- BoonSutazioData=") != std::string::npos){
        return 3;
    }else{
        return 0;
    }
    return 0;
}

bool ConvertBilibiliComment(const char *xml,const char *outfile,int width,int height,const char *font,float fontsize,float alpha,float duration_marquee,float duration_still){
    bilibiliParser *p = new bilibiliParser;
    p->SetFile(xml, outfile);
    p->SetRes(width, height);
    p->SetFont(font, fontsize);
    p->SetDuration(duration_marquee, duration_still);
    p->SetAlpha(alpha);
    return p->Convert(false);
}

bool bilibiliParser::Convert(bool removeBottom){
    Ass *ass = new Ass;
    
    ass->init(out);
    ass->SetDuration(duration_marquee,duration_still);
    ass->WriteHead(width, height, font, fontsize,alpha);
    
    rapidxml::file<> xmlFile(in);
    if(xmlFile.size() < 1){
        return false;
    }
    rapidxml::xml_document<> doc;
    doc.parse<0>(xmlFile.data());
    xml_node<> *node = doc.first_node("i"); // Get comment main node
    
    for (xml_node<> *child = node->first_node("d"); child; child = child->next_sibling()) // Each comment
    {
        std::string v = child->value();
        bool isBlocked = false;
        for (auto i = blockWords.begin();i != blockWords.end(); i++ ){
            if(v.find(*i) != std::string::npos){
                isBlocked = true;
            }
        }
        if(isBlocked){
            continue;
        }

        const char *separator = ","; // Separator of comment properties
        char *p;
        
        /* Arg1 : Appear time
         The time of comment appear.
         */
        p = strtok(child->first_attribute("p")->value(), separator);
        float appear_time = atof(p);
        
        /* Arg2 : Comment mode
         123 - Scroll comment
         4 - Bottom comment
         5 - Top comment
         6 - Reverse comment
         7 - Positioned comment
         8 - Javascript comment ( not convert )
         */
        p = strtok(NULL, separator);
        if(!p){ continue; }
        int comment_mode = atoi(p);
        
        /* Arg3 : Font size ( not needed )*/
        p = strtok(NULL, separator);
        if(!p){ continue; }
        //int font_size = atoi(p);
        
        /* Arg4 : Font color */
        p = strtok(NULL, separator);
        if(!p){ continue; }
        int font_color = atoi(p);
        
        /* Arg5 : Unix timestamp ( not needed ) */
        /* Arg6 : comment pool ( not needed ) */
        /* Arg7 : sender uid ( not needed ) */
        /* Arg8 : database rowID ( not needed ) */
        
        ass->AppendComment(appear_time, comment_mode, font_color, child->value());
    }
    
    
    ass->WriteToDisk(removeBottom);
    
    return true;
}

/*
 Convert comments to .ass subtitle
 
 infile: comment file path
 outfile: output file path
 width: video width
 height: video height
 font: font name
 alpha: comment alpha
 duration_marquee:Duration of scrolling comment
 duration_still:Duration of still comment
 */

void danmaku2ass(const char *infile,const char *outfile,int width,int height,const char *font,float fontsize,float alpha,float duration_marquee,float duration_still){
    std::ifstream input(infile);
    string headline;
    getline(input,headline);
    int type = GetCommentType(headline);
    if(type == 1){
        //cout << "Avfun format detected ! Converting..." << endl;
        cout << "Sorry , The format is not supported" << endl;
    }else if(type == 2){
        cout << "Bilibili format detected ! Converting..." << endl;
        bool result = ConvertBilibiliComment(infile,outfile,width,height,font,fontsize,alpha,duration_marquee,duration_still);
        if(result){
            cout << "Convert succeed" << endl;
        }else{
            cout << "Convert failed" << endl;
        }
    }else if(type == 3){
        //cout << "Niconico format detected ! Converting..." << endl;
        cout << "Sorry , The format is not supported" << endl;
    }else{
        cout << "ERROR: Unable to get comment type" << endl;
    }
    input.close();
}


#ifndef __danmaku2ass_native__NoMainFunc__

int main(int argc,char *argv[]){
    cout << "Starting danmaku2ass native..." << endl;
    clock_t begin = clock();
    
    map<string,string> args;
    
    int count;
    for (count=0; count<argc; count++){
        char *param = argv[count];
        char *str = strchr(param,'='); // Get value for param
        if(str){
            int pos = (int)(str - param); // Get position of "="
            char *keybuf = (char *)malloc(pos-1 * sizeof(char));
            strncpy(keybuf, param + 1, (size_t)pos-1); // Get key for param
            keybuf[pos-1] = '\0';
            args[keybuf] = str+1;
        }else{
            continue;
        }
    }
    
    danmaku2ass(
                args["in"].c_str(), // Input file ( must be utf-8 )
                args["out"].c_str(), // Output file
                stoi(args["w"]), // Video width
                stoi(args["h"]), // Video height
                args["font"].c_str(), // Comment Font
                stoi(args["fontsize"]), // Font Size
                stof(args["alpha"]), // Comment Alpha
                stof(args["dm"]), // Duration of scrolling comment
                stof(args["ds"]) // Duration of still comment
                );
    
    clock_t end = clock();
    double elapsed_secs = double(end - begin) / CLOCKS_PER_SEC;
    
    cout << "Exiting... Time taken:" << elapsed_secs << "s"<< endl;
    
    return 0;
}

#endif