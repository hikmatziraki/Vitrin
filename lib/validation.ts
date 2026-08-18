import {z} from 'zod';
export const id=z.string().uuid(); export const zoneId=z.number().int().min(1).max(6); export const moduleType=z.enum(['energy','workshop','storage','lab']);
export const missionStart=z.object({zoneId,explorerId:id}); export const eventChoice=z.object({missionId:id,eventIndex:z.number().int().min(0).max(1),choice:z.number().int().min(0).max(2)});
export const upgrade=z.object({type:moduleType}); export const craft=z.object({recipeId:z.number().int().positive()}); export const levelup=z.object({explorerId:id}); export const marketList=z.object({itemId:id,price:z.number().int().positive()}); export const marketBuy=z.object({listingId:id});
