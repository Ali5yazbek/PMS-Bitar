import { useTranslation } from 'react-i18next';
import React, { useState, useRef, useEffect } from 'react';
import { MessageSquare, X, Send, Bot, User, Loader2 } from 'lucide-react';
import api from '../api/axios';

const AIChatAssistant = ({ onTriggerExport }) => {
  const { t } = useTranslation();

  const [isOpen, setIsOpen] = useState(false);
  const [messages, setMessages] = useState([
    { id: 1, text: "Hello! I am your AI Generator Assistant. Ask me about fuel consumption, maintenance, or reports.", isBot: true }
  ]);
  const [input, setInput] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const messagesEndRef = useRef(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages, isOpen]);

  const handleSend = async (e) => {
    e.preventDefault();
    if (!input.trim()) return;

    const userMessage = { id: Date.now(), text: input, isBot: false };
    setMessages(prev => [...prev, userMessage]);
    setInput('');
    setIsLoading(true);

    try {
      const res = await api.post('/energy/ai/chat', { query: userMessage.text });
      const responseText = res.data.response;
      
      if (responseText === 'ACTION_TRIGGER_EXPORT') {
        setMessages(prev => [...prev, { id: Date.now() + 1, text: "Generating and downloading your report now...", isBot: true }]);
        if (onTriggerExport) onTriggerExport();
      } else {
        setMessages(prev => [...prev, { id: Date.now() + 1, text: responseText, isBot: true }]);
      }
    } catch (error) {
      console.error(error);
      setMessages(prev => [...prev, { id: Date.now() + 1, text: "Sorry, I am having trouble connecting to the server.", isBot: true }]);
    } finally {
      setIsLoading(false);
    }
  };

  // Helper to format bold text coming from backend
  const formatText = (text) => {
    const parts = text.split(/(\*\*.*?\*\*)/g);
    return parts.map((part, index) => {
      if (part.startsWith('**') && part.endsWith('**')) {
        return <strong key={index} className="text-white">{part.slice(2, -2)}</strong>;
      }
      return <span key={index}>{part}</span>;
    });
  };

  return (
    <>
      {/* Floating Chat Button */}
      <button
        onClick={() => setIsOpen(true)}
        className={`fixed bottom-6 right-6 bg-primary hover:bg-indigo-600 text-white p-4 rounded-full shadow-2xl shadow-primary/40 transition-all duration-300 z-50 ${isOpen ? 'scale-0 opacity-0' : 'scale-100 opacity-100'} animate-bounce`}
      >
        <MessageSquare size={24} />
      </button>

      {/* Chat Window */}
      <div 
        className={`fixed bottom-6 right-6 w-96 h-[500px] glass-card border border-slate-700 shadow-2xl flex flex-col z-50 transition-all duration-300 transform origin-bottom-right ${isOpen ? 'scale-100 opacity-100' : 'scale-0 opacity-0 pointer-events-none'}`}
      >
        {/* Header */}
        <div className="bg-slate-800/80 p-4 border-b border-slate-700 flex justify-between items-center rounded-t-xl">
          <div className="flex items-center gap-3">
            <div className="bg-primary/20 p-2 rounded-lg text-primary">
              <Bot size={20} />
            </div>
            <div>
              <h3 className="font-bold text-white">{t('aichatassistant.ai_assistant', { defaultValue: `AI Assistant` })}</h3>
              <p className="text-xs text-success">{t('aichatassistant.online', { defaultValue: `Online` })}</p>
            </div>
          </div>
          <button onClick={() => setIsOpen(false)} className="text-muted hover:text-white transition-colors">
            <X size={20} />
          </button>
        </div>

        {/* Messages */}
        <div className="flex-1 overflow-y-auto p-4 space-y-4 hide-scrollbar">
          {messages.map(msg => (
            <div key={msg.id} className={`flex ${msg.isBot ? 'justify-start' : 'justify-end'}`}>
              <div className={`max-w-[80%] rounded-2xl p-3 text-sm ${
                msg.isBot ? 'bg-slate-800 text-indigo-100 border border-slate-700 rounded-tl-none' 
                          : 'bg-primary text-white rounded-tr-none'
              }`}>
                {msg.isBot ? formatText(msg.text) : msg.text}
              </div>
            </div>
          ))}
          {isLoading && (
            <div className="flex justify-start">
              <div className="bg-slate-800 border border-slate-700 rounded-2xl rounded-tl-none p-3">
                <Loader2 size={16} className="text-primary animate-spin" />
              </div>
            </div>
          )}
          <div ref={messagesEndRef} />
        </div>

        {/* Input Form */}
        <form onSubmit={handleSend} className="p-4 border-t border-slate-700 bg-slate-800/50 rounded-b-xl flex gap-2">
          <input 
            type="text" 
            value={input}
            onChange={(e) => setInput(e.target.value)}
            placeholder={t('aichatassistant.ask_me_anything', { defaultValue: `Ask me anything...` })}
            className="flex-1 bg-slate-900 border border-slate-700 rounded-lg px-4 py-2 text-white text-sm focus:border-primary outline-none transition-colors"
          />
          <button 
            type="submit" 
            disabled={!input.trim() || isLoading}
            className="bg-primary hover:bg-indigo-600 disabled:opacity-50 text-white p-2.5 rounded-lg transition-colors flex items-center justify-center"
          >
            <Send size={18} />
          </button>
        </form>
      </div>
    </>
  );
};

export default AIChatAssistant;
