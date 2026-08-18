import {serverSupabase} from '@/lib/server/supabase';
export async function balance<T=unknown>(key:string,fallback:T){const s=await serverSupabase();const {data}=await s.from('balance_config').select('value').eq('key',key).maybeSingle();return (data?.value as T)??fallback}
