// middleware.jsx
import { NextResponse } from 'next/server';
import { getToken } from 'next-auth/jwt';

// This is the secret used in your NextAuth configuration
const secret = process.env.NEXTAUTH_SECRET;

export async function middleware(req) {
  console.log('testingMiddle')
  const secureCookie = req.headers.get("https") == "on" || process.env.NEXTAUTH_URL.startsWith('https://');
  const token = await getToken({ req, secret, secureCookie });
  // console.log(token);
  const { pathname } = req.nextUrl;

  // Exclude API routes and static files from authentication
  if (
    pathname.startsWith('/api/') ||
    pathname.startsWith('/images/') ||
    pathname.includes('/static/') ||
    pathname === '/privacy-policy' ||
    pathname === '/terms-of-service' ||
    pathname === '/ContactUs' ||
    pathname === '/Auth'
  ) {
    return NextResponse.next();
  }

  // If there's no token and the request is for a page other than the auth pages, redirect to auth page
  if (!token && !pathname.includes('/api/auth')) {
    const url = req.nextUrl.clone();
    url.pathname = '/api/auth/signin';
    return NextResponse.redirect(url);
  }

  return NextResponse.next();
}
