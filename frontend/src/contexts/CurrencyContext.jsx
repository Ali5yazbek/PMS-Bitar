import React, { createContext, useContext, useState, useEffect } from 'react';
import api from '../api/axios';

const CurrencyContext = createContext();

export const useCurrency = () => {
  return useContext(CurrencyContext);
};

export const CurrencyProvider = ({ children }) => {
  const [currency, setCurrency] = useState('CFA');
  const [exchangeRate, setExchangeRate] = useState(600);
  const [isInitialized, setIsInitialized] = useState(false);

  useEffect(() => {
    // 1. Try to fetch from API to get the latest exchange rate
    const fetchSettings = async () => {
      try {
        const token = localStorage.getItem('token');
        if (token) {
          const res = await api.get('/auth/me');
          if (res.data?.settings?.exchange_rate) {
            setExchangeRate(res.data.settings.exchange_rate);
          }
        }
      } catch (err) {
        console.error("Failed to fetch exchange rate:", err);
      }
    };

    fetchSettings();

    // 2. Initialize the preferred currency
    const saved = localStorage.getItem('preferred_currency');
    if (saved) {
      setCurrency(saved);
    } else {
      // Check user role
      try {
        const user = JSON.parse(localStorage.getItem('user'));
        if (user && user.role === 'agent') {
          setCurrency('USD');
          localStorage.setItem('preferred_currency', 'USD');
        } else {
          setCurrency('CFA');
          localStorage.setItem('preferred_currency', 'CFA');
        }
      } catch (err) {
        setCurrency('CFA');
      }
    }
    
    setIsInitialized(true);
  }, []);

  const toggleCurrency = () => {
    setCurrency((prev) => {
      const next = prev === 'CFA' ? 'USD' : 'CFA';
      localStorage.setItem('preferred_currency', next);
      return next;
    });
  };

  const formatAmount = (amountCFA) => {
    if (!amountCFA || isNaN(amountCFA)) amountCFA = 0;
    const cfaValue = parseFloat(amountCFA);

    if (currency === 'USD') {
      const usdValue = cfaValue / exchangeRate;
      return `$${usdValue.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })} USD`;
    } else {
      return `CFA ${cfaValue.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
    }
  };

  return (
    <CurrencyContext.Provider value={{ currency, toggleCurrency, exchangeRate, formatAmount, isInitialized }}>
      {children}
    </CurrencyContext.Provider>
  );
};
