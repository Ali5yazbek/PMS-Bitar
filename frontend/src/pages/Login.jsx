import { useTranslation } from 'react-i18next';
import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import api from '../api/axios';
import { Mail, Lock, Eye, EyeOff, ArrowRight, Zap, Coins, Globe, ChevronDown } from 'lucide-react';

const Login = () => {
  const { t, i18n } = useTranslation();
  const navigate = useNavigate();
  const [loginIdentifier, setLoginIdentifier] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [keepSignedIn, setKeepSignedIn] = useState(false);
  const [isLangMenuOpen, setIsLangMenuOpen] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    
    try {
      const res = await api.post('/auth/login', { loginIdentifier, password });
      localStorage.setItem('token', res.data.token);
      localStorage.setItem('user', JSON.stringify(res.data.user));
      navigate('/');
    } catch (err) {
      setError(err.response?.data?.error || 'Login failed');
    } finally {
      setLoading(false);
    }
  };

  const changeLanguage = (lng) => i18n.changeLanguage(lng);

  return (
    <div className="min-h-screen bg-[#0b0c10] flex flex-col font-sans text-slate-300 relative overflow-hidden">
      {/* Background glow effects */}
      <div className="absolute top-[-20%] left-[-10%] w-[50%] h-[50%] rounded-full bg-indigo-900/20 blur-[120px] pointer-events-none"></div>
      <div className="absolute bottom-[-20%] right-[-10%] w-[50%] h-[50%] rounded-full bg-purple-900/10 blur-[120px] pointer-events-none"></div>

      {/* Header */}
      <header className="w-full p-6 flex justify-between items-center z-50 relative">
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 bg-[#8b5cf6] rounded-lg flex items-center justify-center text-white font-bold text-lg shadow-[0_0_15px_rgba(139,92,246,0.3)]">
            P
          </div>
          <span className="font-bold text-xl tracking-wide text-white">PMS System</span>
        </div>
        
        <div className="flex items-center gap-4">
          <div className="flex items-center gap-2 px-3 py-1.5 bg-slate-800/50 border border-slate-700/50 rounded-full text-xs font-medium">
            <div className="w-2 h-2 rounded-full bg-emerald-500 shadow-[0_0_8px_rgba(16,185,129,0.5)]"></div>
            <span className="text-slate-300">{t('System Online')}</span>
          </div>
          
          <div className="relative z-50">
            <button 
              type="button"
              onClick={() => setIsLangMenuOpen(!isLangMenuOpen)}
              className="flex items-center gap-2 px-3 py-1.5 bg-slate-800/50 border border-slate-700/50 rounded-lg text-xs font-medium hover:bg-slate-700/50 transition-colors"
            >
              <Globe size={14} className="text-indigo-400" />
              <span>{i18n.language === 'fr' ? 'Français' : i18n.language === 'ar' ? 'العربية' : 'English'}</span>
              <ChevronDown size={14} className={`text-slate-400 transition-transform ${isLangMenuOpen ? 'rotate-180' : ''}`} />
            </button>
            
            {isLangMenuOpen && (
              <div 
                className="fixed inset-0 z-40" 
                onClick={(e) => {
                  e.stopPropagation();
                  setIsLangMenuOpen(false);
                }}
              ></div>
            )}
            
            <div className={`absolute right-0 top-full mt-2 w-36 bg-slate-800 border border-slate-700 rounded-lg shadow-xl transition-all duration-200 z-50 ${isLangMenuOpen ? 'opacity-100 visible pointer-events-auto' : 'opacity-0 invisible pointer-events-none'}`}>
               <div className="py-1 flex flex-col w-full">
                 <button type="button" onClick={() => { changeLanguage('en'); setIsLangMenuOpen(false); }} className="w-full px-4 py-2 text-left text-sm text-slate-300 hover:bg-slate-700 hover:text-white transition-colors">English</button>
                 <button type="button" onClick={() => { changeLanguage('fr'); setIsLangMenuOpen(false); }} className="w-full px-4 py-2 text-left text-sm text-slate-300 hover:bg-slate-700 hover:text-white transition-colors">Français</button>
                 <button type="button" onClick={() => { changeLanguage('ar'); setIsLangMenuOpen(false); }} className="w-full px-4 py-2 text-left text-sm text-slate-300 hover:bg-slate-700 hover:text-white transition-colors">العربية</button>
               </div>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-1 flex items-center justify-center p-4 z-10 relative">
        <div className="w-full max-w-[420px] bg-[#1a1c29] rounded-2xl shadow-2xl border border-slate-700/50 p-8 relative overflow-hidden">
          {/* Subtle top border highlight */}
          <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-indigo-500 via-purple-500 to-indigo-500"></div>

          <div className="mb-8">
            <h1 className="text-2xl font-bold text-white mb-2">{t('Welcome Back')}</h1>
            <p className="text-sm text-slate-400">{t('Sign in to access your dashboard')}</p>
          </div>

          {error && (
            <div className="bg-red-500/10 border border-red-500/30 text-red-400 p-3 rounded-lg text-sm mb-6 text-center">
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-5">
            <div>
              <label className="block text-xs font-semibold text-slate-400 uppercase tracking-wider mb-2">{t('login.email_address', 'Email or Username')}</label>
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <Mail size={16} className="text-slate-500" />
                </div>
                <input
                  type="text"
                  value={loginIdentifier}
                  onChange={(e) => setLoginIdentifier(e.target.value)}
                  className="w-full pl-10 pr-4 py-2.5 bg-[#13151f] border border-slate-700/50 rounded-lg text-white placeholder-slate-500 focus:outline-none focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 transition-all text-sm"
                  placeholder={t('name@company.com')}
                  required
                />
              </div>
            </div>
            
            <div>
              <div className="flex justify-between items-center mb-2">
                <label className="block text-xs font-semibold text-slate-400 uppercase tracking-wider">{t('login.password', 'Password')}</label>
                <a href="#" className="text-[11px] text-[#8b5cf6] hover:text-indigo-300 transition-colors font-medium">{t('Forgot Password?')}</a>
              </div>
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <Lock size={16} className="text-slate-500" />
                </div>
                <input
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="w-full pl-10 pr-10 py-2.5 bg-[#13151f] border border-slate-700/50 rounded-lg text-white placeholder-slate-500 focus:outline-none focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 transition-all text-sm"
                  placeholder={t('Enter your password')}
                  required
                />
                <button 
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute inset-y-0 right-0 pr-3 flex items-center text-slate-500 hover:text-slate-300 transition-colors"
                >
                  {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                </button>
              </div>
            </div>

            <div className="flex items-center pt-1">
              <label className="flex items-center cursor-pointer">
                <div className="relative flex items-center">
                  <input
                    type="checkbox"
                    checked={keepSignedIn}
                    onChange={(e) => setKeepSignedIn(e.target.checked)}
                    className="peer appearance-none w-4 h-4 border border-slate-600 rounded bg-[#13151f] checked:bg-[#8b5cf6] checked:border-[#8b5cf6] focus:outline-none transition-colors"
                  />
                  <svg className="absolute w-3 h-3 text-white left-0.5 pointer-events-none opacity-0 peer-checked:opacity-100 transition-opacity" viewBox="0 0 14 10" fill="none" xmlns="http://www.w3.org/2000/svg">
                    <path d="M1 5L4.5 8.5L13 1" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                  </svg>
                </div>
                <span className="ml-2 text-xs text-slate-400 font-medium">{t('Keep me signed in')}</span>
              </label>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full bg-[#8b5cf6] hover:bg-[#7c3aed] text-white font-semibold py-2.5 px-4 rounded-lg transition-all duration-200 disabled:opacity-70 flex justify-center items-center shadow-[0_4px_14px_0_rgba(139,92,246,0.3)] group mt-4 text-sm"
            >
              <span>{loading ? t('Signing in...') : t('login.sign_in', 'Sign In to Dashboard')}</span>
              {!loading && <ArrowRight size={16} className="ml-2 group-hover:translate-x-1 transition-transform" />}
            </button>
          </form>

          {/* Bottom badges */}
          <div className="mt-8 pt-6 border-t border-slate-700/50 grid grid-cols-2 gap-4">
            <div className="bg-[#13151f] rounded-lg p-3 flex flex-col justify-center items-center text-center border border-slate-800/80">
              <span className="text-[9px] text-slate-500 font-bold uppercase tracking-wider mb-1">{t('Active Modules')}</span>
              <div className="flex items-center gap-1.5 text-xs font-medium text-[#8b5cf6]">
                <Zap size={12} className="fill-[#8b5cf6]" />
                <span>{t('Rent & Utilities')}</span>
              </div>
            </div>
            
            <div className="bg-[#13151f] rounded-lg p-3 flex flex-col justify-center items-center text-center border border-slate-800/80">
              <span className="text-[9px] text-slate-500 font-bold uppercase tracking-wider mb-1">{t('Currency Supported')}</span>
              <div className="flex items-center gap-1.5 text-xs font-medium text-slate-300">
                <Coins size={12} className="text-slate-400" />
                <span>{t('CFA / USD / EUR')}</span>
              </div>
            </div>
          </div>
        </div>
      </main>

      {/* Footer */}
      <footer className="w-full p-6 flex justify-between items-center text-xs text-slate-500 z-10 relative mt-auto">
        <div>
          © 2026 <span className="font-semibold text-slate-400">PMS System</span>. All Rights Reserved.
        </div>
        <div className="flex gap-4">
          <a href="#" className="hover:text-slate-300 transition-colors">Privacy Policy</a>
          <a href="#" className="hover:text-slate-300 transition-colors">Terms of Service</a>
          <a href="#" className="hover:text-slate-300 transition-colors">Support</a>
        </div>
      </footer>
    </div>
  );
};

export default Login;
