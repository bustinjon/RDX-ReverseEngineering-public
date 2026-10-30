import com.rdx.fullscreen.usbhelper.HondaPhonePolicy;

public final class HondaPhonePolicyTest {
    private static int checks;
    private static void check(boolean value) {
        checks++;
        if (!value) throw new AssertionError("Policy check " + checks);
    }
    public static void main(String[] args) {
        HondaPhonePolicy legacy = new HondaPhonePolicy(null);
        check(!legacy.isCooperative());
        check(!legacy.allowsRaw(false, "phone-a"));
        check(legacy.allowsRaw(true, "phone-a"));
        HondaPhonePolicy phone = new HondaPhonePolicy("phone-a");
        check(phone.isCooperative());
        check(phone.allowsRaw(false, "phone-a"));
        check(phone.allows("phone-a"));
        check(!phone.allows("phone-b"));
        check(!phone.allows(null));
        check(!phone.allowsRaw(true, "phone-b"));
        // Persistence reconstruction uses the same serial on cold/sticky startup.
        check(new HondaPhonePolicy("phone-a").allows("phone-a"));
        for (String bad : new String[]{"", " ", "phone'a", "phone\na", new String(new char[65]).replace('\0', 'a')}) {
            boolean rejected = false;
            try { new HondaPhonePolicy(bad); } catch (IllegalArgumentException expected) { rejected = true; }
            check(rejected);
        }
        System.out.println("PASS: " + checks + " phone policy checks");
    }
}
