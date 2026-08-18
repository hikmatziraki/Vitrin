import {serverSupabase} from './supabase';
export async function requireUser(){const s=await serverSupabase();const {data:{user},error}=await s.auth.getUser();if(error||!user)throw new Error('UNAUTHORIZED');return {s,user}}
