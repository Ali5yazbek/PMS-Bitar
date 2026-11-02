import React from 'react';
import { useCurrency } from '../../contexts/CurrencyContext';
import { motion, AnimatePresence } from 'framer-motion';

const InteractiveCurrency = ({ amountCFA, className = '' }) => {
  const { currency, formatAmount, toggleCurrency } = useCurrency();

  // If amount is null or undefined, default to 0
  const validAmount = amountCFA ?? 0;
  
  const formattedValue = formatAmount(validAmount);

  return (
    <div 
      className={`inline-flex items-center cursor-pointer group relative ${className}`}
      onClick={(e) => {
        e.stopPropagation(); // prevent triggering parent clicks
        toggleCurrency();
      }}
      title={`Click to view in ${currency === 'CFA' ? 'USD' : 'CFA'}`}
    >
      <AnimatePresence mode="wait">
        <motion.span
          key={currency}
          initial={{ opacity: 0, scale: 0.95 }}
          animate={{ opacity: 1, scale: 1 }}
          exit={{ opacity: 0, scale: 1.05 }}
          transition={{ duration: 0.15, ease: "easeOut" }}
          className="relative block"
        >
          {formattedValue}
        </motion.span>
      </AnimatePresence>
      
      {/* Subtle Tooltip */}
      <span className="pointer-events-none absolute -top-8 left-1/2 -translate-x-1/2 whitespace-nowrap rounded bg-slate-800 px-2 py-1 text-xs text-white opacity-0 transition-opacity group-hover:opacity-100 z-50">
        Click to view in {currency === 'CFA' ? 'USD' : 'CFA'}
      </span>
    </div>
  );
};

export default InteractiveCurrency;
