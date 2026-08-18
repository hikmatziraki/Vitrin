import { Redis } from '@upstash/redis';

let client: Redis | null = null;
export function redis(): Redis | null {
  if (client) return client;
  const url=process.env.UPSTASH_REDIS_REST_URL;
  const token=process.env.UPSTASH_REDIS_REST_TOKEN;
  if(!url||!token) return null;
  client=new Redis({url,token});
  return client;
}
export async function withLock<T>(key:string,fn:()=>Promise<T>,ttlSeconds=15):Promise<T>{
  const r=redis();
  if(!r) return fn();
  const lockKey=`voidrun:lock:${key}`;
  const token=crypto.randomUUID();
  const ok=await r.set(lockKey,token,{nx:true,ex:ttlSeconds});
  if(!ok) throw new Error('BUSY_RETRY');
  try{return await fn();}finally{await r.del(lockKey);}
}
