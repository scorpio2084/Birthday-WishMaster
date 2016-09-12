namespace Wish.Common.Infrastructure
{
    public class ModelResponse<T> : Response
        where T : class
    {
        public T Model { get; set; }
    }
}