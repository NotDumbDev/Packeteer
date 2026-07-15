// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

// https://astro.build/config
export default defineConfig({
	site: "https://notdumbdev.github.io",
	base: "/Packeteer/",
	trailingSlash: "always",
	integrations: [
		starlight({
			title: 'Packeteer',
			logo: {
				src: "./src/assets/packety.png"
			},
			favicon: "./favicon.ico",
			social: [{ icon: 'github', label: 'GitHub', href: 'https://github.com/NotDumbDev/Packeteer' }],
			sidebar: [
				{
					label: 'Philosophy',
					items: [
						// Each item here is one entry in the navigation menu.
						{ autogenerate: { directory: 'philosophy' } }
					],
				},
				{
					label: 'Quick Start',
					items: [
						// Each item here is one entry in the navigation menu.
						{ autogenerate: { directory: 'quickstart' } }
					],
				},
				{
					label: 'Packet Events',
					items: [
						// Each item here is one entry in the navigation menu.
						{ autogenerate: { directory: 'packetevents' } }
					],
				},
				{
					label: 'Packet Functions',
					items: [
						// Each item here is one entry in the navigation menu.
						{ autogenerate: { directory: 'packetfunctions' } }
					],
				},
				{
					label: 'Unreliable Packet Events',
					items: [
						// Each item here is one entry in the navigation menu.
						{ autogenerate: { directory: 'unreliablepacketevents' } }
					],
				},
				{
					label: 'Reference',
					items: [{ autogenerate: { directory: 'reference' } }],
				},
			],
			
		}),
	],
});
