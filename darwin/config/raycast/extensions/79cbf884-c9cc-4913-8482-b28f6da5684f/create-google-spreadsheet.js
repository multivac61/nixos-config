"use strict";var b=Object.create;var i=Object.defineProperty;var R=Object.getOwnPropertyDescriptor;var S=Object.getOwnPropertyNames;var _=Object.getPrototypeOf,x=Object.prototype.hasOwnProperty;var I=(t,e)=>()=>(e||t((e={exports:{}}).exports,e),e.exports),C=(t,e)=>{for(var o in e)i(t,o,{get:e[o],enumerable:!0})},h=(t,e,o,n)=>{if(e&&typeof e=="object"||typeof e=="function")for(let r of S(e))!x.call(t,r)&&r!==o&&i(t,r,{get:()=>e[r],enumerable:!(n=R(e,r))||n.enumerable});return t};var E=(t,e,o)=>(o=t!=null?b(_(t)):{},h(e||!t||!t.__esModule?i(o,"default",{value:t,enumerable:!0}):o,t)),P=t=>h(i({},"__esModule",{value:!0}),t);var w=I((j,l)=>{"use strict";function p(t){this.message=t}p.prototype=new Error,p.prototype.name="InvalidCharacterError";var f=typeof window<"u"&&window.atob&&window.atob.bind(window)||function(t){var e=String(t).replace(/=+$/,"");if(e.length%4==1)throw new p("'atob' failed: The string to be decoded is not correctly encoded.");for(var o,n,r=0,a=0,u="";n=e.charAt(a++);~n&&(o=r%4?64*o+n:n,r++%4)?u+=String.fromCharCode(255&o>>(-2*r&6)):0)n="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=".indexOf(n);return u};function A(t){var e=t.replace(/-/g,"+").replace(/_/g,"/");switch(e.length%4){case 0:break;case 2:e+="==";break;case 3:e+="=";break;default:throw"Illegal base64url string!"}try{return function(o){return decodeURIComponent(f(o).replace(/(.)/g,function(n,r){var a=r.charCodeAt(0).toString(16).toUpperCase();return a.length<2&&(a="0"+a),"%"+a}))}(e)}catch{return f(e)}}function s(t){this.message=t}function g(t,e){if(typeof t!="string")throw new s("Invalid token specified");var o=(e=e||{}).header===!0?0:1;try{return JSON.parse(A(t.split(".")[o]))}catch(n){throw new s("Invalid token specified: "+n.message)}}s.prototype=new Error,s.prototype.name="InvalidTokenError";var c=g;c.default=g,c.InvalidTokenError=s,l.exports=c});var U={};C(U,{default:()=>v});module.exports=P(U);var T=require("@raycast/api");var d=require("@raycast/api"),m=E(w());var O=new d.OAuth.PKCEClient({redirectMethod:d.OAuth.RedirectMethod.AppURI,providerName:"Google",providerIcon:"google-logo.png",providerId:"google",description:"Connect your Google account"});async function k(){let e=(await O.getTokens())?.idToken;if(!e)return;let{email:o}=(0,m.default)(e);return o}async function y(t,e){let o=await k(),n=`https://docs.google.com/${t}/create`,r=new URLSearchParams;e&&r.append("title",e),o&&r.append("authuser",o);let a=n+"?"+r.toString();await(0,T.open)(a)}async function v(){await y("spreadsheets")}
