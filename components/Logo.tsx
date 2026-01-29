
import React from 'react';

interface LogoProps {
  className?: string;
  variant?: 'light' | 'dark' | 'brand';
}

const Logo: React.FC<LogoProps> = ({ className = "h-12 w-auto", variant = 'light' }) => {
  // Colors based on the Teatower palette
  const colors = {
    light: "#FFFFFF",
    dark: "#064e3b", // emerald-900
    brand: "#10b981" // emerald-500
  };

  const color = colors[variant];

  return (
    <svg 
      viewBox="0 0 300 100" 
      fill="none" 
      xmlns="http://www.w3.org/2000/svg" 
      className={className}
    >
      {/* Stylized Tower / Tea Leaf Icon */}
      <path 
        d="M40 80C40 80 20 60 20 40C20 20 40 10 40 10C40 10 60 20 60 40C60 60 40 80 40 80Z" 
        fill={color} 
        fillOpacity="0.8"
      />
      <rect x="35" y="45" width="10" height="40" fill={color} />
      <path d="M30 45H50L40 30L30 45Z" fill={color} />
      
      {/* Text "TEATOWER" */}
      <text 
        x="80" 
        y="65" 
        fill={color} 
        style={{ 
          fontFamily: 'serif', 
          fontSize: '42px', 
          fontWeight: 'bold', 
          letterSpacing: '0.05em' 
        }}
      >
        TEATOWER
      </text>
      
      {/* Subtitle */}
      <text 
        x="82" 
        y="85" 
        fill={color} 
        fillOpacity="0.6"
        style={{ 
          fontFamily: 'sans-serif', 
          fontSize: '12px', 
          textTransform: 'uppercase',
          letterSpacing: '0.3em'
        }}
      >
        Belgian Tea House
      </text>
    </svg>
  );
};

export default Logo;
