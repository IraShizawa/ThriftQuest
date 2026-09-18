import fs from 'node:fs/promises';
import path from 'node:path';
import { Presentation, PresentationFile } from '@oai/artifact-tool';
const p = Presentation.create({slideSize:{width:1280,height:720}});
const navy='#101522', gold='#FFD95A', pink='#FF2E68', white='#FFF9EE', muted='#B9C0D0';
function box(slide,text,x,y,w,h,size,color=white,bold=false){const s=slide.shapes.add({geometry:'textbox',position:{left:x,top:y,width:w,height:h},fill:'none',line:{fill:'none',width:0}});s.text=text;s.text.style={typeface:'Avenir Next',fontSize:size,color,bold,autoFit:'shrink'};return s}
function base(slide,kicker,title){slide.background.fill=navy;box(slide,kicker,70,42,1140,30,18,gold,true);box(slide,title,70,86,1140,74,42,white,true);box(slide,'THRIFTQUEST / 貯金RPG',70,665,500,24,14,muted,false)}
function line(slide,x,y,w,color){slide.shapes.add({geometry:'rect',position:{left:x,top:y,width:w,height:5},fill:color,line:{fill:color,width:0}})}
// 1
{const s=p.slides.add();base(s,'DAY 4–5 PRESENTATION','欲しいものを、ボス攻略に変える');box(s,'皆さんも、欲しいものを見つけて\n「今すぐ買いたい」と思ったことはありませんか？',72,205,1050,92,30,white,true);box(s,'その「欲しい」を、貯金のモチベーションに変えるアプリです。',72,335,1050,48,25,gold,true);box(s,'貯金RPG – ThriftQuest',72,450,900,52,32,white,true);box(s,'発表者：伊良 志澤',72,515,700,38,22,muted,false);line(s,72,405,180,pink)}
// 2
{const s=p.slides.add();base(s,'01 / 作品概要','貯金を「ボス攻略」として楽しむ');box(s,'欲しいスニーカーや旅行をボスとして登録。価格がHPになり、稼いだお金や我慢できた金額をPOWERに変えて攻撃します。',80,230,1080,110,28,white,false);box(s,'HPを0にする ＝ 買うためのお金を貯めきる',80,420,1040,55,30,gold,true);box(s,'数字の管理から、達成感のあるゲーム体験へ',80,510,1000,42,22,muted,false);line(s,80,375,250,pink)}
// 3
{const s=p.slides.add();base(s,'02 / コア機能','3つの画面で、攻略が続く');const items=[['POWERを記録','稼いだ金額・使わずに守った金額を記録',80],['攻撃する','POWERを好きなボスへ配分してHPを削る',390],['図鑑に残す','撃破したボスをコレクションとして保存',700]];for(const [t,d,x] of items){box(s,t,x,245,260,42,25,gold,true);box(s,d,x,320,260,100,20,white,false);line(s,x,390,220,pink)}box(s,'⚡  POWER        ⚔  攻撃        ▣  図鑑',80,520,1050,48,28,white,true)}
// 4
{const s=p.slides.add();base(s,'03 / DAY 4–5','目標と進捗');box(s,'目標',80,220,180,42,26,gold,true);box(s,'コア機能を1本の体験としてつなぐ',80,275,480,48,28,white,true);box(s,'進捗',700,220,180,42,26,gold,true);box(s,'ホーム、記録、攻撃、図鑑を実装\nShare ExtensionとAI生成も動作確認',700,275,470,105,25,white,false);line(s,80,410,1080,pink);box(s,'現在はTestFlight配布に向けて署名・App Group設定を調整中',80,485,1080,44,23,muted,false)}
// 5
{const s=p.slides.add();base(s,'04 / NEXT','これから行うこと');box(s,'① TestFlightで実機テスト',90,230,1000,42,28,white,true);box(s,'② Share Extensionのサイト別取得精度を改善',90,315,1000,42,28,white,true);box(s,'③ AIボス生成の体験を磨く',90,400,1000,42,28,white,true);box(s,'④ ウィジェットで毎日の攻略状況を確認',90,485,1000,42,28,white,true);box(s,'「欲しい」を、買う前に遊べるアプリへ。',90,590,1050,45,26,gold,true);line(s,90,545,220,pink)}
const out='/Users/ira/Desktop/LA_iPhone/ThriftQuest/presentation-output/thriftquest-day4-day5-v2.pptx';await (await PresentationFile.exportPptx(p)).save(out);console.log(out);
