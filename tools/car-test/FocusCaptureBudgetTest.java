import com.rdx.fullscreen.usbhelper.FocusCaptureBudget;
public final class FocusCaptureBudgetTest {
    private static int checks;
    private static void check(boolean value){checks++;if(!value)throw new AssertionError("check "+checks);}
    public static void main(String[] args){
        FocusCaptureBudget budget=new FocusCaptureBudget(100);
        check(budget.reserve(99)==-1);check(budget.reserve(100)==1);
        for(long time=101;time<10100;time++)check(budget.reserve(time)==-1);
        for(int n=2;n<=12;n++)check(budget.reserve(100+(n-1)*10000L)==n);
        check(budget.reserve(120100)==-1);check(budget.finished(120100));
        FocusCaptureBudget expired=new FocusCaptureBudget(100);
        check(expired.reserve(120100)==-1);check(expired.finished(120100));
        FocusCaptureBudget stopped=new FocusCaptureBudget(100);stopped.close();check(stopped.reserve(100)==-1);
        FocusCaptureBudget rollback=new FocusCaptureBudget(100);check(rollback.reserve(10000)==1);check(rollback.reserve(9999)==-1);
        System.out.println("PASS: "+checks+" capture-budget assertions");
    }
}
