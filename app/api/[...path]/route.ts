import {NextResponse} from 'next/server';
import {requireUser} from '@/lib/server/guard';
import {serverSupabase} from '@/lib/server/supabase';
import {missionStart,eventChoice,upgrade,craft,levelup,marketList,marketBuy,id} from '@/lib/validation';
import {enforceRateLimit} from '@/lib/server/rate-limit';

async function dispatch(req:Request,parts:string[]){
 const method=req.method; const path=parts.join('/');
 if(path==='auth/guest'&&method==='POST'){const s=await serverSupabase();const {data,error}=await s.auth.signInAnonymously();if(error)throw error;return NextResponse.json({userId:data.user?.id});}
 if(path==='auth/email'&&method==='POST'){const b=await req.json().catch(()=>({}));if(typeof b.email!=='string'||!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(b.email))return NextResponse.json({error:'INVALID_EMAIL'},{status:400});const s=await serverSupabase();const {error}=await s.auth.signInWithOtp({email:b.email,options:{emailRedirectTo:process.env.NEXT_PUBLIC_SITE_URL?`${process.env.NEXT_PUBLIC_SITE_URL}/base`:undefined}});if(error)throw error;return NextResponse.json({ok:true,message:'Magic link sent if the address is eligible.'});}
 const {s,user}=await requireUser();
 const rate=await enforceRateLimit(`user:${user.id}:${path}`);if(!rate.success)return NextResponse.json({error:'RATE_LIMITED'},{status:429});
 if(method==='GET'){
  if(path==='state'){const [profile,currency,modules,energy,explorers,missions,crafts]=await Promise.all([s.from('profiles').select('*').eq('user_id',user.id).maybeSingle(),s.from('currencies').select('*').eq('user_id',user.id).maybeSingle(),s.from('modules').select('*').eq('user_id',user.id).order('type'),s.from('energy').select('*').eq('user_id',user.id).maybeSingle(),s.from('explorers').select('*').eq('user_id',user.id).order('id'),s.from('missions').select('*').eq('user_id',user.id).order('started_at',{ascending:false}).limit(10),s.from('craft_queue').select('*,recipes(*)').eq('user_id',user.id).order('started_at',{ascending:false})]);return NextResponse.json({profile:profile.data,currency:currency.data,modules:modules.data??[],energy:energy.data,explorers:explorers.data??[],missions:missions.data??[],crafts:crafts.data??[]});}
  if(path==='zones'){const {data,error}=await s.from('zones').select('*').order('id');if(error)throw error;return NextResponse.json(data??[]);}
  if(path==='recipes'){const {data,error}=await s.from('recipes').select('*').order('id');if(error)throw error;return NextResponse.json(data??[]);}
  if(path==='market/listings'){const {data,error}=await s.from('market_listings').select('id,item_id,price,seller_id,created_at,items(type,subtype,rarity,durability)').eq('status','active').order('created_at',{ascending:false});if(error)throw error;return NextResponse.json(data??[]);}
  if(path==='seasons/current'){const {data}=await s.from('seasons').select('*').order('id',{ascending:false}).limit(1).maybeSingle();return NextResponse.json(data??null);}
  if(path==='leaderboard'){const {data}=await s.from('leaderboard_snapshots').select('*').order('rank').limit(100);return NextResponse.json(data??[]);}
  if(path==='explorers/catalog'){const {data}=await s.from('explorer_catalog').select('*').order('id');return NextResponse.json(data??[]);}
  if(path==='decisions'){const {data}=await s.from('decision_event_bank').select('id,zone_id,clue,choices,explanation').order('id');return NextResponse.json(data??[]);}
  if(path==='admin/balance'||path==='admin/economy'||path==='admin/audit-logs'){if(user.email!==process.env.VOIDRUN_ADMIN_EMAIL)throw new Error('FORBIDDEN');if(path==='admin/balance'){const {data}=await s.from('balance_config').select('*').order('key');return NextResponse.json(data??[]);}if(path==='admin/economy'){const {data,error}=await s.rpc('economy_dashboard');if(error)throw error;return NextResponse.json(data);}const {data}=await s.from('audit_logs').select('*').order('created_at',{ascending:false}).limit(200);return NextResponse.json(data??[]);}
  return NextResponse.json({error:'NOT_FOUND'},{status:404});
 }
 const body=await req.json().catch(()=>({}));let data,error;
 if(path==='missions/start'){const x=missionStart.parse(body);({data,error}=await s.rpc('start_mission',{p_user_id:user.id,p_zone_id:x.zoneId,p_explorer_id:x.explorerId}));}
 else if(path==='missions/event-choice'){const x=eventChoice.parse(body);({data,error}=await s.rpc('record_mission_choice',{p_user_id:user.id,p_mission_id:x.missionId,p_event_index:x.eventIndex,p_choice:x.choice}));}
 else if(path==='missions/resolve'){({data,error}=await s.rpc('resolve_due_missions',{p_user_id:user.id}));}
 else if(path==='base/upgrade'){const x=upgrade.parse(body);({data,error}=await s.rpc('upgrade_module',{p_user_id:user.id,p_type:x.type}));}
 else if(path==='craft/start'){const x=craft.parse(body);({data,error}=await s.rpc('start_craft',{p_user_id:user.id,p_recipe_id:x.recipeId}));}
 else if(path==='craft/collect'){({data,error}=await s.rpc('collect_craft',{p_user_id:user.id}));}
 else if(path==='explorers/levelup'){const x=levelup.parse(body);({data,error}=await s.rpc('level_up_explorer',{p_user_id:user.id,p_explorer_id:x.explorerId}));}
 else if(path==='explorers/ascend'){const x=id.parse(body.explorerId);({data,error}=await s.rpc('ascend_explorer',{p_user_id:user.id,p_explorer_id:x}));}
 else if(path==='market/list'){const x=marketList.parse(body);({data,error}=await s.rpc('list_market_item',{p_user_id:user.id,p_item_id:x.itemId,p_price:x.price}));}
 else if(path==='market/buy'){const x=marketBuy.parse(body);({data,error}=await s.rpc('buy_market_item',{p_buyer_id:user.id,p_listing_id:x.listingId}));}
 else if(path==='guild/create'){if(typeof body.name!=='string'||body.name.length<3||body.name.length>32)throw new Error('INVALID_NAME');({data,error}=await s.rpc('create_guild',{p_user_id:user.id,p_name:body.name}));}
 else if(path==='raids/join'){({data,error}=await s.rpc('join_raid',{p_user_id:user.id,p_raid_id:body.raidId}));}
 else if(path==='prestige'){({data,error}=await s.rpc('prestige',{p_user_id:user.id}));}
 else if(path==='wallet/connect'||path==='wallet/withdraw')return NextResponse.json({enabled:false,message:'Phase 4 wallet functionality is disabled.'},{status:403});
 else if(path==='admin/balance'&&method==='PUT'){if(user.email!==process.env.VOIDRUN_ADMIN_EMAIL)throw new Error('FORBIDDEN');({data,error}=await s.from('balance_config').upsert({key:body.key,value:body.value,updated_at:new Date().toISOString()}).select().single());}
 else throw new Error('NOT_FOUND');
 if(error)throw error;return NextResponse.json(data??{ok:true});
}
export async function GET(req:Request,{params}:{params:Promise<{path:string[]}>}){try{return await dispatch(req,(await params).path)}catch(e){return NextResponse.json({error:e instanceof Error?e.message:String(e)},{status:400})}}
export async function POST(req:Request,{params}:{params:Promise<{path:string[]}>}){try{return await dispatch(req,(await params).path)}catch(e){return NextResponse.json({error:e instanceof Error?e.message:String(e)},{status:400})}}
export async function PUT(req:Request,{params}:{params:Promise<{path:string[]}>}){try{return await dispatch(req,(await params).path)}catch(e){return NextResponse.json({error:e instanceof Error?e.message:String(e)},{status:400})}}
