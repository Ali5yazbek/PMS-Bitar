import React, { useEffect, useState, useRef } from 'react';
import { Html5Qrcode as ImportedHtml5Qrcode } from 'html5-qrcode';
import { Camera } from 'lucide-react';

// Handle Webpack 5 CJS/ESM interop safely without triggering static export errors
const Html5Qrcode = typeof ImportedHtml5Qrcode === 'function' 
  ? ImportedHtml5Qrcode 
  : (ImportedHtml5Qrcode?.Html5Qrcode || ImportedHtml5Qrcode);

const QRScanner = ({ onScanSuccess }) => {
  const [error, setError] = useState(null);
  const scannerRef = useRef(null);
  const scannerId = useRef(`qr-reader-${Math.random().toString(36).substring(2, 9)}`);

  useEffect(() => {
    if (typeof Html5Qrcode !== 'function') {
      setError("QR Scanner library failed to load correctly.");
      return;
    }
    
    const targetId = scannerId.current;
    if (!document.getElementById(targetId)) return;
    
    let html5QrCode = new Html5Qrcode(targetId);
    scannerRef.current = html5QrCode;
    
    // PRD: Aggressively tuned to 10 FPS to preserve battery and prevent thermal throttling
    const config = { fps: 10, qrbox: { width: 250, height: 250 } };
    
    // PRD: Target the environment-facing (rear) camera of the mobile device by default
    html5QrCode.start(
      { facingMode: "environment" }, 
      config,
      (decodedText) => {
        if (html5QrCode.isScanning) {
          html5QrCode.stop().then(() => {
            onScanSuccess(decodedText);
          }).catch((err) => console.error("Failed to stop scanning.", err));
        }
      },
      (errorMessage) => {
        // ignore background scan optical errors
      }
    ).catch(err => {
      setError("Camera unavailable. Please check device permissions.");
    });

    return () => {
      if (scannerRef.current && scannerRef.current.isScanning) {
        scannerRef.current.stop().catch(console.error);
      }
    };
  }, [onScanSuccess]);

  return (
    <div className="w-full h-full flex flex-col items-center justify-center bg-black">
      {error ? (
        <div className="p-4 text-center">
          <Camera className="mx-auto text-slate-600 mb-2" size={32} />
          <p className="text-danger font-bold text-sm">{error}</p>
        </div>
      ) : (
        <div id={scannerId.current} className="w-full h-full object-cover"></div>
      )}
    </div>
  );
};

export default QRScanner;
