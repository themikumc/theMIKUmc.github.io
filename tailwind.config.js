/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{vue,js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        base: '#0b0f12',
        panel: '#10171c',
        mint: '#5adcf0',
        line: '#1c2a32',
        soft: '#9cb2bd'
      },
      fontFamily: {
        sans: ['Space Grotesk', 'Segoe UI', 'sans-serif']
      },
      boxShadow: {
        glow: '0 0 0 1px rgba(90,220,240,0.16), 0 8px 20px rgba(0,0,0,0.24)'
      }
    }
  },
  plugins: []
}
