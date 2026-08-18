export const clamp=(n:number,min:number,max:number)=>Math.min(max,Math.max(min,n));
export const moduleCost=(c0:number,l:number)=>Math.round(c0*Math.pow(1.35,l-1));
export const moduleTime=(t0:number,l:number)=>Math.ceil(t0*Math.pow(1.25,l-1));
export const successProbability=(statMatch:number,gearScore:number,hazardEffective:number,fatigue:number)=>clamp(.75+.15*statMatch+.10*gearScore-.9*hazardEffective-fatigue,.15,.95);
export const marketTax=(price:number)=>({burn:price*.02,treasury:price*.02,rewards:price*.01,total:price*.05});
export const emissionCap=(sink7d:number,k:number,max:number)=>Math.min(max,k*sink7d);
