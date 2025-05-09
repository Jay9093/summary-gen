from sumy.parsers.plaintext import PlaintextParser
from sumy.nlp.tokenizers import Tokenizer
from sumy.summarizers.lsa import LsaSummarizer
from sumy.nlp.stemmers import Stemmer
from sumy.utils import get_stop_words

def summarize_text(text, sentence_count=3):
    try:
        # Create the parser
        parser = PlaintextParser.from_string(text, Tokenizer("english"))
        
        # Create the summarizer
        stemmer = Stemmer("english")
        summarizer = LsaSummarizer(stemmer)
        summarizer.stop_words = get_stop_words("english")
        
        # Summarize the text
        summary = summarizer(parser.document, sentence_count)
        return " ".join([str(sentence) for sentence in summary])
    except Exception as e:
        # Fallback to simple summarization if something goes wrong
        return text[:500] + "..." if len(text) > 500 else text
