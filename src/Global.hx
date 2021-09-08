import tink.core.Promise;

class Global
{
    public static function p<A>(promise:js.lib.Promise<A>):Promise<A>
    {
        return Promise.ofJsPromise(promise);
    }
}
