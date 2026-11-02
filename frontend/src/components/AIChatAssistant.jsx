import React from 'react';
import { useNavigate } from 'react-router-dom';
import { Bot } from 'lucide-react';

const AIChatAssistant = () => {
  const navigate = useNavigate();

  return (
    <button
      onClick={() => navigate('/ai-chat')}
      className="fixed bottom-6 right-6 bg-gradient-to-br from-indigo-600 to-purple-600 hover:from-indigo-500 hover:to-purple-500 text-white p-4 rounded-full shadow-2xl shadow-indigo-500/40 transition-all duration-300 z-50 hover:scale-110 flex items-center justify-center group"
      title="Open AI Agency"
    >
      <Bot size={28} className="group-hover:animate-pulse" />
      
      {/* Optional: Glow effect behind */}
      <span className="absolute inset-0 rounded-full border-2 border-white/20 animate-ping"></span>
    </button>
  );
};

export default AIChatAssistant;
