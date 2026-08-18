import {describe,it,expect} from 'vitest';
import {moduleCost,moduleTime,successProbability,marketTax,emissionCap} from '../lib/economy';
import {energyCap,energyRegenPerHour,explorerLevelCost,prestigeYieldMultiplier,workshopCraftTime} from '../lib/balance/formulas';

describe('VOIDRUN economy',()=>{
 it('matches module curve',()=>{expect(moduleCost(100,1)).toBe(100);expect(moduleCost(100,2)).toBe(135);expect(moduleTime(2,1)).toBe(2);expect(moduleTime(2,2)).toBe(3)});
 it('matches energy rules',()=>{expect(energyCap(1)).toBe(100);expect(energyCap(5)).toBe(180);expect(energyRegenPerHour(1)).toBe(5);expect(energyRegenPerHour(5)).toBe(9)});
 it('matches success clamp',()=>{expect(successProbability(1,1,0,0)).toBe(.95);expect(successProbability(0,0,1,0)).toBe(.15)});
 it('splits market tax',()=>{expect(marketTax(100)).toEqual({burn:2,treasury:2,rewards:1,total:5})});
 it('governs emission',()=>expect(emissionCap(1000,1,500)).toBe(500));
 it('matches explorer level cost',()=>{expect(explorerLevelCost(1)).toBe(50);expect(explorerLevelCost(2)).toBe(65)});
 it('applies workshop speed',()=>expect(workshopCraftTime(240,1)).toBe(223));
 it('caps prestige yield at +50%',()=>{expect(prestigeYieldMultiplier(0)).toBe(1);expect(prestigeYieldMultiplier(10)).toBe(1.5);expect(prestigeYieldMultiplier(20)).toBe(1.5)});
});
