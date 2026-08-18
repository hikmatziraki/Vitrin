import './globals.css';
import {Nav} from '@/components/nav';
import {PWA} from '@/components/pwa';
export const metadata={title:'VOIDRUN — Last Runner',description:'Explore. Decide. Survive.',manifest:'/manifest.webmanifest'};
export default function RootLayout({children}:{children:React.ReactNode}){return <html lang="en"><body><PWA/><Nav/><main className="min-h-screen pb-24 lg:pl-64 lg:pb-0">{children}</main></body></html>}
