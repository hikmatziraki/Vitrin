import { Ratelimit } from '@upstash/ratelimit';
import { Redis } from '@upstash/redis';
let limiter:Ratelimit|null=null;
function getLimiter(){
 if(limiter) return limiter;
 const url=process.env.UPSTASH_REDIS_REST_URL, token=process.env.UPSTASH_REDIS_REST_TOKEN;
 if(!url||!token) return null;
 limiter=new Ratelimit({redis:new Redis({url,token}),limiter:Ratelimit.slidingWindow(60,'1 m'),analytics:true,prefix:'voidrun:rate'});
 return limiter;
}
export async function enforceRateLimit(identifier:string){
 const l=getLimiter();
 if(!l) return {success:true,remaining:Infinity};
 return l.limit(identifier);
}
