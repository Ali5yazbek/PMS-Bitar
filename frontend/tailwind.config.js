/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./src/**/*.{js,jsx,ts,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        background: '#0F172A',
        sidebar: '#111827',
        cards: '#1E293B',
        primary: '#6366F1',
        secondary: '#8B5CF6',
        success: '#22C55E',
        danger: '#EF4444',
        warning: '#F59E0B',
        darktext: '#F8FAFC',
        muted: '#94A3B8'
      }
    },
  },
  plugins: [],
}
