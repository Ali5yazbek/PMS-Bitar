import React, { forwardRef } from 'react';

const PrintableDailyCollection = forwardRef(({ collections, agentName, date, totalCollected }, ref) => {
  return (
    <div className="hidden">
      <div ref={ref} className="p-8 bg-white text-black font-sans w-full min-h-screen">
        
        {/* Header */}
        <div className="flex justify-between items-start border-b-2 border-black pb-6 mb-6">
          <div>
            <h1 className="text-3xl font-bold uppercase mb-2">Daily Collection Report</h1>
            <p className="text-lg text-gray-700">Agent: <span className="font-bold text-black">{agentName}</span></p>
            <p className="text-lg text-gray-700">Date: <span className="font-bold text-black">{date}</span></p>
          </div>
          <div className="text-right">
            <h2 className="text-2xl font-bold">Total Collected</h2>
            <p className="text-3xl font-extrabold">${totalCollected.toFixed(2)}</p>
          </div>
        </div>

        {/* Table */}
        <div className="mb-12">
          <table className="w-full text-left border-collapse border border-gray-300">
            <thead>
              <tr className="bg-gray-100">
                <th className="border border-gray-300 px-4 py-3 font-bold uppercase text-sm">#</th>
                <th className="border border-gray-300 px-4 py-3 font-bold uppercase text-sm">Building</th>
                <th className="border border-gray-300 px-4 py-3 font-bold uppercase text-sm">Apt</th>
                <th className="border border-gray-300 px-4 py-3 font-bold uppercase text-sm">Tenant Name</th>
                <th className="border border-gray-300 px-4 py-3 font-bold uppercase text-sm">Payment Method</th>
                <th className="border border-gray-300 px-4 py-3 font-bold uppercase text-sm text-right">Amount</th>
              </tr>
            </thead>
            <tbody>
              {collections.length === 0 ? (
                <tr>
                  <td colSpan="6" className="border border-gray-300 px-4 py-8 text-center text-gray-500 italic">
                    No collections recorded for this period.
                  </td>
                </tr>
              ) : (
                collections.map((col, idx) => (
                  <tr key={idx} className="hover:bg-gray-50">
                    <td className="border border-gray-300 px-4 py-2">{idx + 1}</td>
                    <td className="border border-gray-300 px-4 py-2 font-semibold">{col.building}</td>
                    <td className="border border-gray-300 px-4 py-2">{col.apartment}</td>
                    <td className="border border-gray-300 px-4 py-2">{col.tenant}</td>
                    <td className="border border-gray-300 px-4 py-2">{col.method}</td>
                    <td className="border border-gray-300 px-4 py-2 font-bold text-right">${Number(col.amount).toFixed(2)}</td>
                  </tr>
                ))
              )}
            </tbody>
            {collections.length > 0 && (
              <tfoot>
                <tr className="bg-gray-100 font-bold text-lg">
                  <td colSpan="5" className="border border-gray-300 px-4 py-3 text-right">Grand Total:</td>
                  <td className="border border-gray-300 px-4 py-3 text-right">${totalCollected.toFixed(2)}</td>
                </tr>
              </tfoot>
            )}
          </table>
        </div>

        {/* Signatures Section */}
        <div className="mt-16 flex justify-between px-12">
          <div className="text-center w-64">
            <div className="border-b border-black mb-2 h-16"></div>
            <p className="font-bold text-gray-700">Agent Signature</p>
            <p className="text-sm mt-1">{agentName}</p>
          </div>
          
          <div className="text-center w-64">
            <div className="border-b border-black mb-2 h-16"></div>
            <p className="font-bold text-gray-700">Company Receiver Signature</p>
            <p className="text-sm mt-1">Management Office</p>
          </div>
        </div>

        {/* Footer */}
        <div className="mt-12 text-center text-sm text-gray-500 border-t border-gray-200 pt-4">
          Generated automatically by Bitar Management System
        </div>
      </div>
    </div>
  );
});

export default PrintableDailyCollection;
