using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;

namespace Wish.Common.Infrastructure
{
    public class Response
    {
        public Response()
        {
            Errors = new Collection<string>();
        }

        public ICollection<string> Errors { get; }

        public bool HasErrors => Errors.Any();
    }
}
