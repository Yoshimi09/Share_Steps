import type { ReactNode } from 'react';
import { Footprints, House, Users, UserCircle } from 'lucide-react';
import type { Profile } from '../types';

type LayoutProps = {
  children: ReactNode;
  profile: Profile | null;
  route: string;
  navigate: (path: string) => void;
};

const navItems = [
  { path: '/', label: 'ホーム', icon: House },
  { path: '/groups', label: 'グループ', icon: Users },
  { path: '/mypage', label: 'マイページ', icon: UserCircle },
];

export function Layout({ children, profile, route, navigate }: LayoutProps) {
  return (
    <div className="app-shell">
      <header className="topbar">
        <button className="brand-button" type="button" onClick={() => navigate('/')}>
          <span className="brand-mark">
            <Footprints size={22} aria-hidden="true" />
          </span>
          <span>Share Steps</span>
        </button>
        <div className="signed-in-user">{profile?.username ?? '読み込み中'}</div>
      </header>

      <nav className="main-nav" aria-label="メインナビゲーション">
        {navItems.map((item) => {
          const Icon = item.icon;
          const active = item.path === '/' ? route === '/' : route.startsWith(item.path);

          return (
            <button
              className={active ? 'nav-button active' : 'nav-button'}
              key={item.path}
              type="button"
              onClick={() => navigate(item.path)}
            >
              <Icon size={18} aria-hidden="true" />
              <span>{item.label}</span>
            </button>
          );
        })}
      </nav>

      <main className="content">{children}</main>
    </div>
  );
}
